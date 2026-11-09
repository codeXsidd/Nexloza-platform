# NEXLOZA Project Audit

**Audit date:** 2026-11-09
**Branch:** main
**Latest commit:** 481cba0
**Auditor:** Claude Opus 4.6 (automated + manual inspection)

---

## 1. Repository Overview

| Metric | Value |
|---|---|
| Total commits | 8 |
| Flutter Dart files | 91 |
| SQL migration files | 15 |
| Edge Functions | 6 |
| Firmware SDK files | 6 (.h/.cpp) |
| Firmware examples | 9 (+ 1 Arduino README) |
| CI workflows | 1 (5 jobs) |
| Test files | 1 Flutter + 1 SQL |
| Documentation files | 18 |

## 2. Uncommitted Changes

5 modified files with real functionality (not stubs):
- `app/lib/features/automations/data/automation_repository.dart` — toggle, delete
- `app/lib/features/projects/presentation/screens/create_project_screen.dart` — form improvements
- `app/lib/features/projects/presentation/screens/project_detail_screen.dart` — device list, stats
- `app/lib/features/projects/presentation/screens/projects_screen.dart` — search, filtering
- `backend/supabase/functions/ai-assistant/index.ts` — project context, conversation history

7 untracked directories with new files:
- `app/lib/features/ai_assistant/data/` — AiRepository
- `app/lib/features/ai_assistant/presentation/providers/` — AiChatNotifier
- `app/lib/features/automations/presentation/providers/` — AutomationsNotifier
- `app/lib/features/device_studio/` — Board definitions, code generator, DeviceStudio screen
- `app/lib/features/devices/presentation/providers/` — DevicesNotifier
- `app/lib/features/projects/presentation/providers/` — ProjectsNotifier

**Assessment:** These are real, functional additions. They must be committed before proceeding.

## 3. Test Baseline

### Flutter Tests
- **53 / 53 passed** (0 failed, 0 skipped)
- Coverage: constants, validators, extensions, entities (Project, Device, Automation, Notification, Scene), Result type, Exceptions, Theme, Routes
- **No widget tests** (no screen rendering tests)
- **No integration tests** (no Supabase interaction tests)

### Static Analysis
- **0 errors, 0 warnings, 2 infos** (deprecated `value` parameter on DropdownButtonFormField)

### Formatting
- **11 files** need reformatting (uncommitted changes not yet formatted)

### SQL RLS Tests
- `backend/supabase/tests/rls_integration_test.sql` — 12 tests defined
- **Not runnable without a live Supabase/Postgres instance**
- Tests cover: org creation trigger, user isolation, project ownership, device assignment, telemetry isolation, notification isolation, AI conversation isolation, sensor project consistency, rate limiting, telemetry retention, command isolation, audit logs

## 4. Database Schema Audit

### Tables (28 total across 15 migrations)

| Migration | Tables | Status |
|---|---|---|
| 00001_profiles | profiles | IMPLEMENTED |
| 00002_organizations | organizations, organization_members | IMPLEMENTED |
| 00003_projects | projects, project_members | IMPLEMENTED |
| 00004_devices | devices, device_credentials, device_groups, device_group_members | IMPLEMENTED |
| 00005_sensors_actuators | sensor_definitions, actuator_definitions | IMPLEMENTED |
| 00006_telemetry | telemetry, device_commands, command_results | IMPLEMENTED |
| 00007_dashboards | dashboards, dashboard_widgets | IMPLEMENTED |
| 00008_automations | automations, automation_triggers, automation_conditions, automation_actions, automation_executions | IMPLEMENTED |
| 00009_scenes | scenes, scene_actions | IMPLEMENTED |
| 00010_notifications | notifications, notification_preferences | IMPLEMENTED |
| 00011_integrations | integrations, integration_events | IMPLEMENTED |
| 00012_ai | ai_conversations, ai_messages | IMPLEMENTED |
| 00013_audit | audit_logs | IMPLEMENTED |
| 00014_firmware | firmware_versions, ota_deployments | IMPLEMENTED |
| 00015_validation_fixes | (fixes + functions) | IMPLEMENTED |

### RLS Coverage
- All 28 tables have RLS enabled
- Helper functions: `is_org_member`, `is_org_admin`, `is_project_member`, `can_modify_project`
- Validation triggers: sensor/actuator project_id consistency
- Utility functions: `cleanup_old_telemetry`, `cleanup_old_audit_logs`, `check_telemetry_rate_limit`

### Missing Tables (from requirements)
- `api_keys` (user-level API keys for external access)
- `usage_records` (AI token tracking, quota management)
- `device_events` (separate from telemetry — connection, error events)

## 5. Edge Functions Audit

| Function | Auth | DB Integration | External API | Gap |
|---|---|---|---|---|
| ai-assistant | JWT (user) | Conversations, messages, project context | Bedrock, Grok | No streaming, no tool calling |
| automation-engine | None (internal) | Triggers, executions, cooldown, rate limit | None | **Actions logged but NOT dispatched** — no MQTT publish, no notification send |
| device-auth | API key + SHA-256 | Device credentials, last_seen | None | Uses SHA-256 not bcrypt/argon2 |
| device-command | JWT (user) | Commands table | None | **Command NOT published to MQTT** — only stored in DB |
| telemetry-ingest | API key + SHA-256 | Telemetry, rate limit | None | Working as designed |
| webhook-handler | HMAC signature | Integration events, automation triggers | None | Working as designed |

### Critical Backend Gaps
1. **automation-engine** records execution but does not actually run actions (no MQTT command publish, no notification dispatch, no webhook call)
2. **device-command** inserts commands into DB but has no MQTT bridge to deliver them to devices
3. No **MQTT-to-Supabase bridge** exists — telemetry from MQTT must go through the Edge Function HTTP endpoint, not directly from the broker

## 6. Flutter App Audit

### Architecture
- Feature-first folder structure (clean architecture pattern)
- Riverpod state management (StateNotifier + AsyncNotifier)
- GoRouter with auth redirect guard
- Material 3 theme (light + dark) with custom design tokens
- Supabase client initialized from environment variables

### Feature Coverage

| Feature | Screens | Data Layer | Provider | Status |
|---|---|---|---|---|
| Authentication | Login, Register, ForgotPassword, EmailVerification, Splash | Supabase Auth | AuthNotifier | **IMPLEMENTED** |
| Home | HomeScreen | — | — | **PARTIALLY IMPLEMENTED** (static widgets) |
| Projects | ProjectsScreen, CreateProject, ProjectDetail | ProjectRepository (CRUD) | ProjectsNotifier | **IMPLEMENTED** |
| Devices | DevicesScreen, AddDevice, DeviceDetail, DevicePairing | DeviceRepository (CRUD + stream) | DevicesNotifier | **PARTIALLY IMPLEMENTED** |
| Automations | AutomationsScreen, CreateAutomation | AutomationRepository (CRUD) | AutomationsNotifier | **PARTIALLY IMPLEMENTED** |
| AI Assistant | AiAssistantScreen | AiRepository (send, conversations, messages) | AiChatNotifier | **IMPLEMENTED** |
| Notifications | NotificationsScreen | NotificationRepository (CRUD) | — | **PARTIALLY IMPLEMENTED** (no provider) |
| Settings | SettingsScreen, ProfileScreen | — | — | **PARTIALLY IMPLEMENTED** (UI only) |
| Device Studio | DeviceStudioScreen | BoardDefinitions, CodeGenerator | — | **PARTIALLY IMPLEMENTED** |
| Dashboards | — | — | — | **MISSING** |
| Sensors/Actuators | — | — | — | **MISSING** |
| Organizations | — | — | — | **MISSING** (DB exists) |
| Integrations | — | — | — | **MISSING** |

### Missing Flutter Components
- **No dashboard editor** (DB schema exists, no Flutter UI)
- **No sensor/actuator management screens** (DB schema exists)
- **No organization management** (DB + RLS exist, no Flutter screens)
- **No integration management** (DB exists, no Flutter screens)
- No push notification setup (FCM)
- No MQTT connection UI (service exists but not wired to screens)
- No real-time data display (Supabase Realtime not used)
- No data export
- No search/filter across most screens
- No pagination beyond initial page load

## 7. Firmware SDK Audit

### NexlozaClient Library
- **IMPLEMENTED**: begin, connect, disconnect, loop, isConnected
- **IMPLEMENTED**: publishTelemetry (3 overloads), reportState, reportDeviceInfo
- **IMPLEMENTED**: onCommand, onConnectionChange, acknowledgeCommand
- **IMPLEMENTED**: enableOTA, checkForUpdate (request only, no download)
- **IMPLEMENTED**: LWT, heartbeat, exponential backoff reconnection
- **PARTIALLY IMPLEMENTED**: NexlozaWiFi (header exists, implementation needs verification)
- **PARTIALLY IMPLEMENTED**: NexlozaProvisioning (captive portal — header exists)

### Firmware Examples (9 + 1 README)
All ESP32/ESP8266 examples have platformio.ini and main.cpp. Not compile-tested in CI (PlatformIO not installed in GitHub Actions).

## 8. Integrations Audit

| Integration | Status | What Exists |
|---|---|---|
| Alexa | **PLACEHOLDER** | skill.json manifest only, no Lambda handler |
| Google Home | **PLACEHOLDER** | README only |
| Home Assistant | **PLACEHOLDER** | README only |
| Matter | **PLACEHOLDER** | README only |
| Node-RED | **PLACEHOLDER** | README only |
| Webhooks | **IMPLEMENTED** | Edge Function + DB + HMAC |

## 9. CI/CD Audit

**ci.yml** has 5 jobs: analyze, test, build-web, build-android, validate-backend, validate-firmware.

| Job | Status |
|---|---|
| Flutter format check | IMPLEMENTED |
| Flutter analyze | IMPLEMENTED |
| Flutter test | IMPLEMENTED |
| Web build | IMPLEMENTED |
| Android APK build | IMPLEMENTED (main only) |
| SQL migration validation | IMPLEMENTED (existence check) |
| Edge Function validation | IMPLEMENTED (existence check) |
| Firmware SDK validation | IMPLEMENTED (existence check) |
| PlatformIO compilation | **MISSING** (commented out) |
| Secret scanning | **MISSING** |
| Dependency auditing | **MISSING** |
| RLS test execution | **MISSING** |
| Edge Function type checking | **MISSING** |

## 10. Documentation Audit

### Complete
- ARCHITECTURE.md (system architecture, data flows)
- docs/architecture/database.md (full schema docs)
- docs/architecture/security.md (comprehensive security model)
- docs/api/mqtt-protocol.md (topic structure, payload schemas)
- docs/setup/local-development.md (dev setup guide)
- docs/VALIDATION_REPORT.md (DB validation audit)
- SECURITY.md, CODE_OF_CONDUCT.md, CONTRIBUTING.md

### Stubs / Index-Only
- docs/getting-started/README.md
- docs/backend/README.md
- docs/firmware/README.md
- docs/integrations/README.md
- docs/security/README.md

### Missing (required by spec)
- THIRD_PARTY_NOTICES.md
- docs/INSTALLATION.md
- docs/API.md
- docs/ARDUINO_GUIDE.md
- docs/ESP32_GUIDE.md
- docs/ESP8266_GUIDE.md
- docs/ALEXA_SETUP.md
- docs/GOOGLE_HOME_SETUP.md
- docs/AI_SETUP.md
- docs/DEPLOYMENT.md
- docs/TROUBLESHOOTING.md

### Known Issues
- **License inconsistency:** LICENSE file is Apache 2.0, but README.md and CONTRIBUTING.md reference MIT
- **CHANGELOG stale:** Only one entry, does not reflect 8 commits of real work
- **Logo missing:** README references `docs/assets/nexloza-logo.png` which does not exist

## 11. Security Findings

1. **No secrets detected** in committed code — env vars used correctly
2. Device credential hashing uses SHA-256 (should upgrade to bcrypt/argon2 for production)
3. CORS headers use `*` wildcard in all Edge Functions (acceptable for dev, restrict for production)
4. Bedrock auth endpoint in firmware SDK uses HTTP basic approach (acceptable for internal API)
5. EMQX ACL is deny-by-default with device-scoped topics — good
6. No rate limiting on user-facing Edge Functions (only telemetry-ingest has rate limiting)
