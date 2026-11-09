# NEXLOZA Project Audit — Phase 0

**Audit date:** 2026-11-09
**Branch:** main
**Latest commit:** 637623e
**Previous audit commit:** 481cba0
**Auditor:** Claude Opus 4.6 (automated + manual inspection)

---

## 1. Repository Overview

| Metric | Previous (481cba0) | Current (637623e) |
|---|---|---|
| Total commits | 8 | 10 |
| Flutter Dart files | 91 | 148 |
| SQL migration files | 15 | 16 |
| Edge Functions | 6 | 6 |
| Firmware SDK files | 6 (.h/.cpp) | 6 (.h/.cpp) |
| Firmware examples | 9 (+ 1 Arduino README) | 10 (+ 1 Arduino README) |
| CI workflows | 1 (5 jobs) | 1 (6 jobs) |
| Test files | 1 Flutter + 1 SQL | 5 Flutter + 1 SQL |
| Tests passing | 53 | 223 |
| Routes defined | 30 | 36 |
| Routes wired | 22 | 36 |
| Feature modules | 12 | 18 |

## 2. Git State

- **Branch:** main
- **Working tree:** Clean (no uncommitted changes)
- **Remote:** Up to date with origin/main
- **Supabase linked:** gwxaansxqdxkofrplfqx (Nexloza-platform, ap-southeast-1)
- **Supabase status:** ACTIVE_HEALTHY, 16 migrations applied, 6 Edge Functions deployed

## 3. Flutter App Inventory

### Feature Modules (18 total, 148 Dart files)

| Feature | Files | Screens | Data Layer | Provider | Status |
|---|---|---|---|---|---|
| authentication | 8 | Login, Register, ForgotPassword, EmailVerification, Splash | Supabase Auth | AuthNotifier | **IMPLEMENTED** |
| home | 5 | HomeScreen + 4 widgets | Real providers | — | **IMPLEMENTED** |
| projects | 9 | Projects, Create, Detail, Edit | ProjectRepository | ProjectsNotifier | **IMPLEMENTED** |
| devices | 26 | Devices, Add, Detail, Edit, Pairing, ManageSensors, ManageActuators | DeviceRepo, SensorRepo, ActuatorRepo, TelemetryRepo, CommandRepo | Device/Sensor/Actuator/Telemetry/Command providers | **IMPLEMENTED** |
| automations | 9 | Automations, Create, Detail | AutomationRepository | AutomationsNotifier | **PARTIALLY IMPLEMENTED** |
| dashboards | 12 | Dashboards, Create, Editor + 5 widget cards | DashboardRepository | DashboardsNotifier | **IMPLEMENTED** |
| ai_assistant | 7 | AiAssistant + ChatBubble, SuggestionCard | AiRepository | AiChatNotifier | **IMPLEMENTED** |
| organizations | 6 | Organizations, Create, Detail | OrganizationRepository | OrganizationNotifier | **IMPLEMENTED** |
| invitations | 4 | Invitations | InvitationRepository | InvitationNotifier | **IMPLEMENTED** |
| scenes | 5 | Scenes, Create | SceneRepository | ScenesNotifier | **PARTIALLY IMPLEMENTED** |
| integrations | 4 | Integrations | IntegrationRepository | IntegrationNotifier | **PARTIALLY IMPLEMENTED** |
| notifications | 3 | Notifications | NotificationRepository | — | **PARTIALLY IMPLEMENTED** |
| analytics | 1 | Analytics dashboard | Uses other providers | — | **IMPLEMENTED** |
| settings | 3 | Settings, Profile, ApiKeys | ProfileRepo | ProfileNotifier | **IMPLEMENTED** |
| device_studio | 3 | DeviceStudio | BoardDefinitions, CodeGenerator | — | **PARTIALLY IMPLEMENTED** |
| profiles | 2 | — | ProfileRepository | ProfileProvider | **IMPLEMENTED** |
| sensors | 1 | — | (entity only) | — | **ENTITY ONLY** |
| actuators | 1 | — | (entity only) | — | **ENTITY ONLY** |

### Routing
- **36 route names** defined in route_names.dart
- **36 routes** wired in app_router.dart (1:1 match)
- Auth redirect guard on all protected routes
- StatefulShellRoute with 5 bottom nav branches (Home, Projects, Devices, Automations, AI)

### Shared Infrastructure
- `Result<T>` sealed type (Success/ResultFailure)
- Supabase client provider
- MQTT service (connect, subscribe, publish, reconnect)
- Offline sync service
- Connectivity provider
- Preferences service
- Network info
- Validators, Logger, Debouncer
- 9 reusable widgets (AppButton, AppTextField, AppScaffold, etc.)
- Material 3 theme with light/dark, custom colors, typography, spacing

### Dependencies (pubspec.yaml)
Core: flutter_riverpod, go_router, supabase_flutter, mqtt_client, shared_preferences, connectivity_plus, intl, uuid, crypto, url_launcher, path_provider

## 4. Database Schema

### Tables (33 total across 16 migrations, ALL with RLS)

| Migration | Tables | RLS Policies |
|---|---|---|
| 00001 profiles | profiles | 3 |
| 00002 organizations | organizations, organization_members | 8 |
| 00003 projects | projects, project_members | 9 |
| 00004 devices | devices, device_credentials, device_groups, device_group_members | 12 |
| 00005 sensors | sensor_definitions, actuator_definitions | 8 |
| 00006 telemetry | telemetry, device_commands, command_results | 6 |
| 00007 dashboards | dashboards, dashboard_widgets | 8 |
| 00008 automations | automations, automation_triggers, automation_conditions, automation_actions, automation_executions | 11 |
| 00009 scenes | scenes, scene_actions | 6 |
| 00010 notifications | notifications, notification_preferences | 4 |
| 00011 integrations | integrations, integration_events | 2 (replaced in 00015) |
| 00012 ai | ai_conversations, ai_messages | 2 |
| 00013 audit | audit_logs | 1 (replaced in 00015) |
| 00014 firmware | firmware_versions, ota_deployments | 3 (replaced in 00015) |
| 00015 validation | Fixes + indexes + functions | 15 new policies |
| 00016 invitations | invitations | 4 + 2 RPC functions |

**Totals:** 33 tables, ~99 RLS policies, ~53 indexes, 14 helper functions

### Tables with Dart repositories (19/33)
actuator_definitions, ai_conversations, ai_messages, automations, dashboard_widgets, dashboards, device_commands, device_credentials, devices, integrations, invitations, notifications, organization_members, organizations, profiles, projects, scenes, sensor_definitions, telemetry

### Tables without Dart repositories (14/33)
audit_logs, automation_actions, automation_conditions, automation_executions, automation_triggers, command_results, device_group_members, device_groups, firmware_versions, integration_events, notification_preferences, ota_deployments, project_members, scene_actions

### Missing tables (from master prompt)
- `usage_records` — AI token tracking, quota management
- `device_events` — connection/error event log
- `api_keys` (user-level) — only device_credentials exists

## 5. Edge Functions (6 deployed)

| Function | Auth | Status | Bugs |
|---|---|---|---|
| ai-assistant | JWT | IMPLEMENTED | Bedrock SigV4 missing (Grok works) |
| automation-engine | JWT | PARTIALLY IMPLEMENTED | notification user_id null constraint violation |
| device-auth | API key | IMPLEMENTED | None |
| device-command | JWT | IMPLEMENTED | None |
| telemetry-ingest | API key | IMPLEMENTED | None |
| webhook-handler | HMAC | PARTIALLY IMPLEMENTED | Executions never marked completed |

### Missing Edge Functions
- alexa-handler (Alexa Smart Home Skill)
- google-home-handler (Google Home Cloud-to-Cloud)
- scene-activate (dedicated scene execution)
- ota-deploy (firmware OTA management)
- voice-command (voice intent processing)

## 6. Firmware SDK

### NexlozaClient API Coverage

| Method | Status |
|---|---|
| begin() | IMPLEMENTED |
| connect() | IMPLEMENTED |
| disconnect() | IMPLEMENTED |
| publishTelemetry() | IMPLEMENTED (3 overloads) |
| reportState() | IMPLEMENTED |
| onCommand() / subscribeCommand() | IMPLEMENTED |
| acknowledgeCommand() | IMPLEMENTED |
| enableOTA() / checkForUpdate() | IMPLEMENTED |
| loop() / heartbeat | IMPLEMENTED (auto) |
| reconnect() | IMPLEMENTED (auto, exponential backoff) |
| registerSensor() | **MISSING** |
| registerActuator() | **MISSING** |
| sendCommand() | **MISSING** |
| setDeviceMetadata() | **MISSING** |

### Firmware Examples

| Example | Board | Status |
|---|---|---|
| esp32-led | ESP32 | IMPLEMENTED |
| esp32-relay-light | ESP32 | IMPLEMENTED |
| esp32-relay-fan | ESP32 | IMPLEMENTED |
| esp32-dht22 | ESP32 | IMPLEMENTED |
| esp32-soil-moisture | ESP32 | IMPLEMENTED |
| esp32-pir-motion | ESP32 | IMPLEMENTED |
| esp32-multi-sensor | ESP32 | IMPLEMENTED |
| esp32-universal | ESP32 | IMPLEMENTED |
| esp8266-led | ESP8266 | IMPLEMENTED |
| esp8266-relay | ESP8266 | IMPLEMENTED |
| arduino-uno | Arduino | README ONLY |
| raspberry-pi | RPi | IMPLEMENTED (Python) |
| esp32-ultrasonic | ESP32 | **MISSING** |
| esp32-water-level | ESP32 | **MISSING** |

## 7. MQTT Infrastructure

| Component | Status | Detail |
|---|---|---|
| Broker | EMQX 5.8.3 | Docker container, ports 1883/8883/8083/8084/18083 |
| NanoMQ | **NOT CONFIGURED** | Master prompt requires NanoMQ as primary |
| Flutter MQTT service | IMPLEMENTED | mqtt_client package, auto-reconnect, TLS support |
| MQTT providers | IMPLEMENTED | mqttServiceProvider, mqttStatusProvider, mqttMessagesProvider |
| Topic structure | INCONSISTENT | Flutter: `nexloza/{orgId}/{projectId}/{deviceId}/{ch}`, Firmware: `nexloza/{projectId}/{deviceId}/{ch}`, Required: `nexloza/v1/{tenant}/{project}/{device}/{ch}` |

## 8. Integrations

| Integration | Status |
|---|---|
| Alexa Smart Home | PLACEHOLDER (skill.json only) |
| Google Home | PLACEHOLDER (README only) |
| Webhooks | IMPLEMENTED (Edge Function + HMAC) |
| Voice control | **NOT IMPLEMENTED** |
| Virtual device simulator | **NOT IMPLEMENTED** |

## 9. CI/CD

5 jobs in ci.yml: analyze, test, build-web, build-android, validate-backend, validate-firmware

**Missing:** RLS tests, integration tests, Edge Function tests, secret scanning, dependency audit, PlatformIO compilation

## 10. Documentation

**Existing:** PROJECT_AUDIT.md, FEATURE_MATRIX.md, IMPLEMENTATION_ROADMAP.md, VALIDATION_REPORT.md, architecture/overview.md, architecture/database.md, architecture/security.md, api/mqtt-protocol.md, setup/local-development.md, CHANGELOG.md

**Missing (16 files):** INSTALLATION.md, API.md, ARDUINO_GUIDE.md, ESP32_GUIDE.md, ESP8266_GUIDE.md, VIRTUAL_DEVICE_GUIDE.md, GROK_SETUP.md, ALEXA_SETUP.md, GOOGLE_HOME_SETUP.md, DEPLOYMENT.md, TROUBLESHOOTING.md, SELF_HOSTING.md, TECHNICAL_DEBT.md, TEST_BASELINE.md, THIRD_PARTY_NOTICES.md, SCALABILITY_REPORT.md

## 11. Security Findings

1. No secrets in committed code — env vars used correctly
2. `.env.example` uses placeholder values only
3. `.gitignore` covers .env, keystores, service accounts, google-services.json
4. Device credentials use SHA-256 hashing (acceptable, bcrypt/argon2 recommended for production)
5. CORS `*` in Edge Functions (restrict for production)
6. Firmware SDK uses `setInsecure()` for TLS — no cert verification
7. Firmware SDK license says MIT but project is Apache 2.0
8. EMQX default dashboard password `nexloza_mqtt_2024` in docker-compose defaults
