# Local IoT development on Windows

Use the existing checkout, Docker Desktop running Linux containers, Python 3.11 or newer with the Windows `py` launcher, Supabase CLI 2.39.2, Flutter 3.47.5 with Dart 3.13.4, and Android SDK platform tools on PATH. Flutter should use Java 17 for the Android build. Start the existing `emulator-5554` from Android Studio before running the kit.

The kit starts the Supabase CLI's disposable `nexloza-iot-dev` project and API gateway. It applies the tracked migrations and provisions the fixture using a generated development user through Auth and PostgREST. The gateway, Postgres, Mailpit and broker use host ports 54321, 54322, 54324 and 1883 respectively. Free those ports by stopping any competing **development** stacks you own. The kit bypasses the historical root Compose Studio image and its split service ports. It never links a Supabase project or runs a remote database command.

## Start and verify

In a PowerShell terminal at the repository root:

```powershell
git fetch origin
git switch codex/continuation-baseline
git pull --ff-only origin codex/continuation-baseline
.\scripts\iot\Test-Iot.ps1 -Action Setup
.\scripts\iot\Test-Iot.ps1 -Action Backend
```

Leave that terminal open once the Edge Functions report ready. In a second PowerShell terminal at the same repository root:

```powershell
.\scripts\iot\Test-Iot.ps1 -Action Bridge
```

Leave it open after `Bridge subscribed to the scoped telemetry topic`. In a third terminal at the repository root:

```powershell
.\scripts\iot\Test-Iot.ps1 -Action Verify
.\scripts\iot\Test-Iot.ps1 -Action Install
```

`Verify` sends a batch containing temperature and humidity twice. It checks that the authenticated project owner sees exactly one matching row per sensor and another authenticated user sees none. It also replays the batch via the Edge Function. `Install` builds with the public local API key, uses `10.0.2.2` for the Windows host, installs the debug APK on the existing emulator, and starts `com.nexloza.nexloza/.MainActivity`. The debug manifest permits cleartext HTTP to the emulator's host alias. Use this only with the local fixture. The broker is published on host loopback and uses per-fixture passwords and exact topic ACLs.

## Sign in and match a simulator reading

Run each copy command just before pasting into its corresponding field. The kit never prints the values.

```powershell
.\scripts\iot\Test-Iot.ps1 -Action Copy -Field email
.\scripts\iot\Test-Iot.ps1 -Action Copy -Field password
```

Open **IoT Smoke**, then **IoT Temperature** from its device list. Open **Simulator**, choose **Start with MQTT**, and paste the matching values in the **Device API key** and **Device API secret** fields.

```powershell
.\scripts\iot\Test-Iot.ps1 -Action Copy -Field key
.\scripts\iot\Test-Iot.ps1 -Action Copy -Field secret
Set-Clipboard -Value ' '
```

Click **Connect** after pasting, wait for a **Stored temperature** reading, and pause. Match the message UUID shown in the UI with the bridge receipt and the returned database rows. The same batch can legitimately contain several sensor keys. Expect one row for the tuple of device, message ID, and sensor key.

```powershell
.\scripts\iot\Test-Iot.ps1 -Action Rows
.\scripts\iot\Test-Iot.ps1 -Action Logs
```

The transport status **Submitted to MQTT** reports that the client handed a batch to the broker library. Use **Stored temperature** and the row query to verify persistence. The normal **Start** button uses the authenticated Supabase virtual-device policy directly. It does not publish over MQTT. The scoped fixture broker supports temperature-profile telemetry including humidity. Additional agriculture profiles require a separately provisioned fixture and scope. Command delivery and status last-will are not part of this telemetry-only ACL.

Stop the bridge and functions with Ctrl+C in their terminals, then run:

```powershell
.\scripts\iot\Test-Iot.ps1 -Action Stop
```

The ignored `.nexloza-iot` directory holds the local fixture and credentials. Do not share it. The kit restricts directory access and uses the same fixture on restart. Only remove the directory after stopping the stack, and only when you intend to discard its credentials.
