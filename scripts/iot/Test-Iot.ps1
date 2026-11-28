param(
    [ValidateSet('Setup','Backend','Bridge','Verify','Install','Logs','Rows','Copy','Stop')]
    [string]$Action = 'Setup',
    [ValidateSet('email','password','key','secret')]
    [string]$Field = 'email'
)
$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path "$PSScriptRoot/../..")
$device = 'emulator-5554'
$package = 'com.nexloza.nexloza'
$state = Join-Path (Get-Location) '.nexloza-iot'
$python = Join-Path $state 'venv/Scripts/python.exe'
$script = 'scripts/iot/runtime.py'

function Invoke-Checked($Command, [string[]]$Arguments) {
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed (exit $LASTEXITCODE)" }
}

function Assert-Emulator {
    $result = Invoke-Checked adb @('-s', $device, 'get-state')
    if ($result -ne 'device') { throw "$device is unavailable" }
}

function Read-Fixture {
    Get-Content "$state/session.json" -Raw | ConvertFrom-Json
}

switch ($Action) {
    'Setup' {
        foreach ($command in @('docker','supabase','py','flutter','adb')) {
            Get-Command $command -ErrorAction Stop | Out-Null
        }
        Assert-Emulator
        Invoke-Checked docker @('info','--format','{{.ServerVersion}}')
        if ((Invoke-Checked supabase @('--version') | Select-Object -First 1) -ne '2.39.2') {
            throw 'Use Supabase CLI 2.39.2 for this kit'
        }
        $sdk = Invoke-Checked flutter @('--version','--machine') | Out-String | ConvertFrom-Json
        if ($sdk.frameworkVersion -ne '3.47.5' -or $sdk.dartSdkVersion -ne '3.13.4') {
            throw 'Use Flutter 3.47.5 with Dart 3.13.4'
        }
        New-Item -ItemType Directory -Force $state | Out-Null
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        Invoke-Checked icacls @($state, '/inheritance:r', '/grant:r', "${identity}:(OI)(CI)F") | Out-Null
        Invoke-Checked py @('-3','-m','venv',"$state/venv")
        Invoke-Checked $python @('-m','pip','install','--only-binary=:all:','--require-hashes','-r','scripts/iot/requirements.txt')
        Invoke-Checked supabase @('--workdir','backend','start','-x',
            'studio,logflare,vector,storage-api,imgproxy,postgres-meta,edge-runtime') | Out-Null
        $status = Invoke-Checked supabase @('--workdir','backend','status','-o','json') |
            Out-String | ConvertFrom-Json
        if ($status.API_URL -notmatch '^http://(127\.0\.0\.1|localhost):54321$') {
            throw 'Expected a disposable local Supabase API gateway on port 54321'
        }
        Invoke-Checked supabase @('--workdir','backend','migration','up','--local')
        $env:NEXLOZA_PUBLIC_KEY = $status.ANON_KEY
        try {
            Invoke-RestMethod -Uri "$($status.API_URL)/auth/v1/health" -Headers @{apikey=$status.ANON_KEY} | Out-Null
            Invoke-Checked $python @($script,'prepare')
            Invoke-Checked $python @($script,'broker')
        } finally {
            Remove-Item Env:NEXLOZA_PUBLIC_KEY -ErrorAction SilentlyContinue
        }
    }
    'Backend' {
        Invoke-Checked supabase @('--workdir','backend','functions','serve','--no-verify-jwt')
    }
    'Bridge' {
        Invoke-Checked $python @($script,'worker')
    }
    'Verify' {
        Invoke-Checked $python @($script,'e2e')
    }
    'Install' {
        Assert-Emulator
        $fixture = Read-Fixture
        Push-Location app
        try {
            Invoke-Checked flutter @('pub','get','--enforce-lockfile')
            Invoke-Checked flutter @('build','apk','--debug','--no-pub',
                '--dart-define=SUPABASE_URL=http://10.0.2.2:54321',
                "--dart-define=SUPABASE_ANON_KEY=$($fixture.public_key)",
                '--dart-define=MQTT_HOST=10.0.2.2','--dart-define=MQTT_PORT=1883',
                '--dart-define=MQTT_TLS=false')
            Invoke-Checked adb @('-s',$device,'install','-r','build/app/outputs/flutter-apk/app-debug.apk')
            Invoke-Checked adb @('-s',$device,'shell','am','start','-W','-n',"$package/.MainActivity")
        } finally { Pop-Location }
    }
    'Copy' {
        $fixture = Read-Fixture
        Set-Clipboard -Value $fixture.$Field
        Write-Host "Copied disposable $Field to the clipboard"
    }
    'Rows' {
        Invoke-Checked $python @($script,'rows')
    }
    'Logs' {
        $appPid = (Invoke-Checked adb @('-s',$device,'shell','pidof',$package)).Trim()
        if ($appPid -notmatch '^\d+$') { throw 'App process is unavailable' }
        # Save only known, credential-free application markers. Never save raw logcat.
        $markers = Invoke-Checked adb @('-s',$device,'logcat','-d',"--pid=$appPid",'-s','flutter') |
            ForEach-Object {
                if ($_ -match '(MQTT connected|MQTT disconnected|MQTT auto-reconnecting|MQTT auto-reconnected|MQTT connection failed|Simulator telemetry delivery failed)\s*$') {
                    $Matches[1]
                }
            }
        @($markers) | Set-Content "$state/emulator-runtime.log"
    }
    'Stop' {
        Invoke-Checked $python @($script,'stop')
        Invoke-Checked supabase @('--workdir','backend','stop')
        Set-Clipboard -Value ' '
    }
}
