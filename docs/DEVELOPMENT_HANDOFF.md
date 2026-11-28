# Nexloza development handoff

## Baseline inspected

The application baseline is `e486d66077a4cd452dd4fe72b669b2091504a2e4` (Phase 10). On 2026-11-28, a Git fetch confirmed that GitHub PR #1 merged the first handoff commit (`fabbcd6fcc6a48f0bc81217d170f98c7c78769f2`) into `main` at `259fd33afbf3ceeb4b4da7a94a91d79a77d11639`. The remote continuation ref was absent when recovery began and was restored on the same GitHub remote. Git verified that `codex/continuation-baseline` contains `fabbcd6` and the hosted validation commit `76925a6c08589e4179e575dc81566de6cc240856`. [Compare the recovery branch with main](https://github.com/codeXsidd/Nexloza-platform/compare/main...codex/continuation-baseline?expand=1).

| Item | Evidence at this commit |
| --- | --- |
| Flutter features | 22 immediate tracked directories under `app/lib/features/` |
| Screens | 60 Dart files directly under directories named `screen` or `screens`. This is a file count. Routable pages and panels can have a different total. |
| Tests | 25 `*_test.dart` files in `app/test/` and 879 source lines starting with a `test(` or `testWidgets(` call. [Phase 10 completion](PHASE_10_COMPLETION_REPORT.md) reports 879 passing. GitHub Actions reproduced 879 passes at the recovery commit. The cloud-local suite was blocked before discovery. |
| Database | 20 migration files and 43 distinct names in direct `CREATE TABLE` statements. The applied schema and RLS behavior still need validation. |
| Edge Functions | 7 `index.ts` entry points under `backend/supabase/functions/`. Deployment was outside this baseline. |
| Firmware | 22 tracked example directories under `firmware/examples/`. Board builds and hardware verification are pending. |

[README](../README.md), [architecture](../ARCHITECTURE.md), [project audit](PROJECT_AUDIT.md), [Phase 10 audit](PHASE_10_AUDIT_REPORT.md), [Phase 10 completion](PHASE_10_COMPLETION_REPORT.md), and [CI](../.github/workflows/ci.yml) were inspected. The early audit and architecture describe earlier schema and broker setups. CI uses stable Flutter and Java 17 for its Android build. It checks formatting and analysis, runs tests with coverage, builds web, and performs backend and firmware file checks. The backend checks do not apply migrations or run RLS tests. The recovery workflow below was verified through GitHub’s public run page.

## Toolchain and run results

[The manifest](../app/pubspec.yaml) requires Dart `^3.13.4`. [The tracked lockfile](../app/pubspec.lock) sets Flutter `>=3.47.0`. The SDK source checkout under `/workspace/.nexloza-dev/flutter` matches [official Flutter 3.47.5](https://github.com/flutter/flutter/tree/3.47.5), commit `6a19cca56475dbfba1478ee68d7bd0c2ef891da1`. Its `DEPS` points to [stable Dart 3.13.4](https://github.com/dart-lang/sdk/blob/b530c21f7de367b94fb04787bfed9d8e989d75e8/tools/VERSION). The source checkout is present and SDK bootstrap remains incomplete.

| Command invoked from `app/` | Recovery result |
| --- | --- |
| `flutter --version` | Exit 56 before printing the version |
| `dart --version` | Exit 56 before printing the version |
| `flutter doctor -v` | Exit 56 before any doctor diagnostics |
| `flutter pub get` | Exit 56 before dependency resolution |
| `flutter analyze` | Exit 56 before analysis. No analyzer warnings or errors were collected. |
| `flutter test` | Exit 56 before discovery. Zero tests executed. Pass, fail, and skip totals are unavailable. |
| `flutter build web --release` | Exit 56 before compilation. No web build produced. |
| `flutter build apk --debug` | Exit 56 before Android tooling ran. No APK produced. |

Every invocation stopped with `curl: (56) CONNECT tunnel failed, response 403` during the Linux x64 Dart SDK download for Flutter engine `af7e796e161ae0bb1ff0758c71a7105418bd9ded`. A separate request to the official SDK artifact returned the same 403. The managed runtime reported enforced network policy at revision 1 with an empty custom allowlist. The saved onboarding draft contains `storage.googleapis.com` and a pinned install script. Review and save that draft in environment settings so the update reaches the running instance. The cloud shell reported OpenJDK 21, no Android SDK directory through `ANDROID_HOME` or `ANDROID_SDK_ROOT`, and no `adb` on PATH. The Android project and existing CI target Java 17. Android readiness remains unverified until the SDK is available and doctor runs.

After the policy applies, run this in Codex Cloud:

```bash
dev_dir=/workspace/.nexloza-dev
export PATH="$dev_dir/flutter/bin:$PATH"
export PUB_CACHE="$dev_dir/pub-cache" XDG_CONFIG_HOME="$dev_dir/config"
export XDG_CACHE_HOME="$dev_dir/cache" XDG_DATA_HOME="$dev_dir/data"
export CI=true FLUTTER_SUPPRESS_ANALYTICS=true
cd /workspace/Nexloza-platform/app
flutter --version
dart --version
flutter doctor -v
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze --no-pub
flutter test --no-pub --reporter expanded --coverage
flutter build web --release --no-pub
flutter build apk --debug --no-pub
```

Preserve each command's exit status and record the final passed, failed, and skipped counts. The lockfile and application code were unchanged in the baseline.

## GitHub Actions fallback

The [Continuation baseline workflow](../.github/workflows/continuation-baseline.yml) runs on pushes to `codex/continuation-baseline` using GitHub-hosted Ubuntu, Flutter 3.47.5, and Java 17. After a successful locked dependency install, it attempts analysis, tests, release web, and debug APK independently. Each command's exit status is preserved and the `continuation-baseline-logs` artifact collects its output. This workflow does not deploy services or use application credentials.

[GitHub Actions run 46148375896](https://github.com/codeXsidd/Nexloza-platform/actions/runs/46148375896) completed successfully at `76925a6`. The application and lockfile match the Phase 10 baseline.

| Hosted check | Verified result |
| --- | --- |
| Flutter/Dart bootstrap, version commands, and doctor | Passed on GitHub-hosted Ubuntu with the workflow’s Flutter 3.47.5 and Java 17 setup. |
| `flutter pub get --enforce-lockfile` | Passed. |
| `flutter analyze --no-pub` | Passed with no fatal diagnostics. The public job status provides the exit result. Full analyzer and doctor output is in the uploaded logs. |
| `flutter test --no-pub --reporter expanded` | Runner reported `00:09 +879: All tests passed!`. The reporter showed 879 passes, no failures, and no skips. |
| `flutter build web --release --no-pub` | Passed. |
| `flutter build apk --debug --no-pub` | Passed. No device or emulator was used. |
| Upload validation logs | Passed. Open `continuation-baseline-logs` on the run page for individual command output. |

**Next task:** Establish the first end-to-end development smoke test against a disposable Supabase gateway and an authenticated NanoMQ broker. Verify the app on Windows `emulator-5554`: sign in as a development user, create and start a virtual device in a test project, and confirm that one reading for the same device ID and timestamp reaches the expected MQTT topic and Supabase row. Record any broker authentication or duplicate-ingestion failure before changing offline storage or starting feature work. Apply the saved artifact allowlist separately to restore Flutter execution in Codex Cloud.

## Offline synchronization

[OfflineSyncService](../app/lib/core/services/offline_sync_service.dart) stores JSON operations in a SharedPreferences string list named `nexloza_offline_queue`. It replays insert, update, delete, and upsert operations through Supabase. A per-instance flag prevents overlapping replay calls. Failed operations are retained until the fifth failed attempt, when they are dropped. The service declares an online-status controller, but searching `app/lib` and `app/test` found no consumer that activates it, enqueues operations, or tests it.

Before wiring repository writes into the queue, add coverage for persistence, startup and reconnect, retention, enqueue during replay, session changes, and retry/idempotency. The replay currently replaces the stored list with the failures from an earlier snapshot, which can discard an enqueue made during replay. Confirm authenticated user/project isolation of the stored queue, require scoped filters for update/delete, and surface dropped writes. Verify the controller observes asynchronous initialization as well as connectivity. Reuse the existing queue only after these behaviors are covered.

## Virtual devices and MQTT

[SimulatorEngine](../app/lib/features/virtual_devices/data/simulator_engine.dart) manages per-device timers, seeded random generation, profile signals, faults, actuator values, and lifecycle. The [controller](../app/lib/features/virtual_devices/presentation/providers/virtual_device_provider.dart) coordinates simulation and publishing. [TelemetryPublisher](../app/lib/features/virtual_devices/data/telemetry_publisher.dart) emits to MQTT when connected and separately writes telemetry and updates the device record in Supabase. It suppresses Supabase exceptions. If a broker bridge also ingests the same publish, verify whether the two paths create duplicates before changing either writer.

[Root Compose](../docker-compose.yml) runs NanoMQ by default and puts EMQX behind a profile. The [NanoMQ config](../infra/nanomq/config/nanomq.conf) disables anonymous access. The [app device MQTT provider](../app/lib/features/devices/presentation/providers/device_mqtt_provider.dart) passes host, port, and client ID without broker credentials. A successful authenticated broker check therefore does not establish app connectivity. The core MQTT service uses `MqttServerClient`. Browser MQTT transport and app authentication need separate validation.

The current cloud broker passed an authenticated publish-and-subscribe round trip on port 1883. Compose reports it unhealthy because the slim image lacks the `curl` executable used by its health check. These flags keep its WebSocket and HTTP mappings off reserved cloud ports:

```bash
NANOMQ_HTTP_PORT=18081 MQTT_WS_PORT=18083 docker compose up -d --no-deps nanomq
PYTHONPATH=/workspace/.nexloza-dev/python python /workspace/.nexloza-dev/mqtt-smoke.py
```

The previous onboarding run found that the managed Docker daemon could not register `supabase/postgres:15.6.1.143` because it ran out of storage, and `supabase/studio:20240923-71e6a79` returned `manifest unknown`. Compose also defaults both Realtime and Inbucket web to port 54324. Use `INBUCKET_WEB_PORT=54328` when starting that subset. The Compose file exposes individual Supabase services. Use a verified local Supabase API gateway for the application. Apply and test migrations only against a disposable local instance.

## Windows Android verification

Run these commands in PowerShell from the repository root on the Windows machine that owns `emulator-5554`. Use Java 17, Flutter 3.47.5, and your installed Android SDK platform tools. Start a disposable, migrated Supabase gateway and a development MQTT listener on Windows first. The example assumes host ports 54321 and 1883. Supply the local gateway's public client key when prompted. If the device rejects cleartext HTTP, use an emulator-reachable HTTPS development gateway with a trusted certificate and change the URL in the command.

```powershell
Set-Location app
flutter --version
flutter doctor -v
adb -s emulator-5554 get-state
flutter devices
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos --no-pub
flutter test --no-pub --reporter expanded
flutter build apk --debug --no-pub
$anonKey = Read-Host 'Local Supabase public client key'
flutter run -d emulator-5554 --no-pub --dart-define=SUPABASE_URL=http://10.0.2.2:54321 "--dart-define=SUPABASE_ANON_KEY=$anonKey" --dart-define=MQTT_HOST=10.0.2.2 --dart-define=MQTT_PORT=1883
```

`10.0.2.2` addresses the Windows host from the Android emulator. Sign in with a development user, open a development project, create a virtual device, and start/pause/resume/stop its simulator. Verify the project-scoped MQTT payload and the stored reading using the same device ID and timestamp. Test airplane mode, process restart, and reconnect after the offline replay is wired. Check broker logs for authentication rejection with the current client. The repo has no `app/integration_test/` device suite. APK installation, launch, sign-in, MQTT, simulator, and offline behavior on `emulator-5554` remain unverified in Codex Cloud.

## Continuation tasks and file map

| Order | Task and verification | Files |
| --- | --- | --- |
| 1 | Hosted baseline verified. Apply the artifact allowlist and rerun in Codex Cloud when local execution is needed. | `app/pubspec.yaml`, `app/pubspec.lock`, `app/analysis_options.yaml`, `app/test/`, `.github/workflows/ci.yml` |
| 2 | Recover Docker storage and use a supported Studio image or a local Supabase CLI stack. Verify the local gateway, apply the 20 migrations, and run the existing RLS SQL with stop-on-error. Check the fixture and its reported assertions. | `docker-compose.yml`, `.env.example`, `backend/supabase/config.toml`, `backend/supabase/migrations/`, `backend/supabase/seed/`, `backend/supabase/tests/rls_integration_test.sql`, `backend/supabase/functions/` |
| 3 | Validate and wire scoped durable offline replay. Verify startup, reconnect, persisted operations, concurrency, and failure reporting. | `app/lib/core/services/offline_sync_service.dart`, `app/lib/shared/providers/{connectivity_provider,supabase_provider}.dart`, `app/lib/core/storage/preferences_service.dart`, `app/lib/{app,main}.dart`, participating feature repositories, `app/test/` |
| 4 | Verify simulator-to-dashboard delivery with an authenticated broker, a single effective ingestion path, and observable publish failures. Exercise command and twin state, reconnect, and web transport separately. | `app/lib/features/virtual_devices/`, `app/lib/features/devices/presentation/providers/device_mqtt_provider.dart`, `app/lib/core/{services/mqtt_service,constants/mqtt_constants}.dart`, `app/test/phase7_test.dart`, `infra/nanomq/`, `backend/services/mqtt/`, `backend/supabase/functions/{telemetry-ingest,device-auth,device-command}/`, `backend/supabase/migrations/00018_virtual_devices_phase7.sql`, [Phase 7 testing](PHASE_7_TESTING.md) and [virtual MQTT](VIRTUAL_DEVICE_MQTT.md) |
| 5 | Run Windows Android and web smoke checks against the development services. Record screenshots/logs and device details without credentials. | `app/android/`, `app/web/`, `app/lib/config/env_config.dart`, `app/lib/routing/app_router.dart`, [Android setup](ANDROID_SETUP.md) |
| 6 | Scope feature gaps separately after baseline validation. Phase 10 records JS web as its working target and calls out WASM dependency support, voice integrations, firmware/OTA management, custom HTML widgets, device favorites, and a dedicated onboarding wizard. Confirm each against the live code and product priorities before scheduling. | [Phase 10 completion](PHASE_10_COMPLETION_REPORT.md), [feature matrix](FEATURE_MATRIX.md), [technical debt](TECHNICAL_DEBT.md), `app/lib/features/`, `integrations/`, `firmware/` |

## Live IoT continuation

The [Windows IoT kit](LOCAL_DEVELOPMENT_SETUP.md) uses a disposable Supabase CLI stack and an authenticated, device-scoped NanoMQ broker. The simulator can use direct Supabase storage or MQTT through the local bridge, with one ingestion path per session. Current evidence is in the [runtime report](test-results/VIRTUAL_IOT_E2E_TEST.md) and [Android launch report](test-results/EMULATOR_LAUNCH_TEST.md). The original handoff above describes the pre-IoT baseline. Production MQTT identity provisioning, command delivery, physical devices, and local Windows runtime still need their own verification.
