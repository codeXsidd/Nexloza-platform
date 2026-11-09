# NEXLOZA Test Baseline

**Date:** 2026-11-09
**Commit:** 637623e
**Branch:** main

---

## Flutter Tests

### Summary
- **Total tests:** 223
- **Passing:** 223 (100%)
- **Failing:** 0
- **Skipped:** 0
- **Test files:** 5

### Test Files

| File | Tests | Coverage Area |
|---|---|---|
| widget_test.dart | ~10 | App initialization, basic widget rendering |
| phase2_test.dart | ~53 | Auth entities, Project/Org/Invitation entities, Result type, Theme, Routes, Validators |
| device_architecture_test.dart | ~92 | Device/Sensor/Actuator/Telemetry/Command entities, DeviceCredential, DeviceCommand lifecycle, Route names |
| new_features_test.dart | ~23 | Integration entity, Scene entity, Automation detail, Edit project, Route names |
| app_completion_test.dart | ~45 | Dashboard/Widget entities, Notification entities, AI entities, Scene presets, Home widgets, Settings |

### Static Analysis
- `flutter analyze`: **0 issues** (no errors, no warnings, no infos)
- `dart format`: **0 files need formatting** (153 files checked)

### Test Coverage by Feature

| Feature | Unit Tests | Widget Tests | Integration Tests |
|---|---|---|---|
| Authentication | Entity tests | — | — |
| Projects | Entity + CRUD tests | — | — |
| Organizations | Entity tests | — | — |
| Devices | Entity + lifecycle tests | — | — |
| Sensors | Entity tests | — | — |
| Actuators | Entity tests | — | — |
| Telemetry | Entity tests | — | — |
| Commands | Entity + status lifecycle | — | — |
| Dashboards | Entity + widget type tests | — | — |
| Automations | Entity tests | — | — |
| Scenes | Entity + preset tests | — | — |
| Integrations | Entity + type tests | — | — |
| Notifications | Entity tests | — | — |
| AI Assistant | Entity tests | — | — |
| Invitations | Entity tests | — | — |
| Theme | Color/typography checks | — | — |
| Routing | Route name validation | — | — |
| Shared | Result type, Validators | — | — |

### Test Gaps

| Gap | Priority | Description |
|---|---|---|
| Widget tests | HIGH | No screen rendering tests exist |
| Integration tests | HIGH | No Supabase interaction tests |
| MQTT tests | HIGH | No MQTT connection/subscribe/publish tests |
| Provider tests | MEDIUM | No AsyncNotifier state tests |
| Repository tests | MEDIUM | No real API call tests (would need mocks or test DB) |
| Voice tests | — | Feature not implemented |
| Virtual device tests | — | Feature not implemented |
| Alexa/Google tests | — | Features not implemented |

## Backend Tests

### SQL RLS Tests
- **File:** `backend/supabase/tests/rls_integration_test.sql`
- **Tests defined:** 12
- **Status:** NOT RUNNABLE without live Postgres instance
- **Coverage:** Org creation trigger, user isolation, project ownership, device assignment, telemetry isolation, notification isolation, AI conversation isolation, sensor project consistency, rate limiting, telemetry retention, command isolation, audit logs

### Edge Function Tests
- **Status:** None exist
- **Gap:** All 6 Edge Functions lack automated tests

## Firmware Tests

- **Status:** No automated tests
- **Compilation:** Not verified in CI (PlatformIO step commented out)
- **Manual check:** All examples have valid platformio.ini and main.cpp structure

## CI/CD Test Pipeline

### Current (ci.yml)
1. `dart format --set-exit-if-changed .` — ACTIVE
2. `flutter analyze` — ACTIVE
3. `flutter test` — ACTIVE
4. `flutter build web --release` — ACTIVE
5. `flutter build apk --release` (main only) — ACTIVE
6. Migration file validation — ACTIVE
7. Edge Function existence check — ACTIVE
8. Firmware structure check — ACTIVE

### Missing from CI
- RLS test execution against test database
- Edge Function type checking / testing
- PlatformIO firmware compilation
- Secret scanning
- Dependency vulnerability auditing
- Integration test suite
- Performance benchmarks

## Android Build

- **APK:** Built successfully at 57MB
- **Location:** `app/build/app/outputs/flutter-apk/app-release.apk`
- **Emulator testing:** Not performed in this audit (no emulator running)

## Known Test Issues

1. **OOM on low-memory machines:** `flutter test` crashes with "Out of memory" when system memory is constrained. Passes when memory is available. Consider `--concurrency=1` flag.
2. **No mocked Supabase tests:** All repository tests would require either mocking Supabase client or running against a test instance.
3. **No MQTT broker tests:** Would require a running NanoMQ/EMQX instance.
