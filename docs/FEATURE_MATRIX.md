# NEXLOZA Feature Matrix

**Last updated:** 2026-11-09
**Branch:** main (commit 481cba0 + uncommitted changes)

---

## Status Key

| Status | Meaning |
|---|---|
| IMPLEMENTED | Working implementation with code, DB schema, and basic tests |
| PARTIALLY IMPLEMENTED | Some components exist but feature is not end-to-end functional |
| MISSING | Not yet started |
| BLOCKED | Requires external service, credentials, or hardware |
| VERIFIED | Tested against real service or hardware |

---

## 1. Authentication & User Management

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| Email/password sign up | auth.users | Supabase Auth | RegisterScreen | Unit | IMPLEMENTED |
| Email/password sign in | auth.users | Supabase Auth | LoginScreen | Unit | IMPLEMENTED |
| Password reset | auth.users | Supabase Auth | ForgotPasswordScreen | — | IMPLEMENTED |
| Email verification | auth.users | Supabase Auth | EmailVerificationScreen | — | IMPLEMENTED |
| Auto profile creation | profiles | Trigger | — | RLS | IMPLEMENTED |
| Profile editing | profiles | RLS | ProfileScreen | — | PARTIALLY IMPLEMENTED |
| Auth state persistence | — | Supabase session | AuthNotifier | — | IMPLEMENTED |
| Social auth (Google, GitHub) | — | — | SocialAuthButton (UI only) | — | MISSING |
| Account deletion | — | — | — | — | MISSING |

## 2. Organization Management

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| Organization CRUD | organizations | RLS | — | RLS | PARTIALLY IMPLEMENTED |
| Organization members | organization_members | RLS + auto-owner trigger | — | RLS | PARTIALLY IMPLEMENTED |
| Roles (owner/admin/member/viewer) | org_role enum | RLS helpers | — | RLS | PARTIALLY IMPLEMENTED |
| Organization invitations | — | — | — | — | MISSING |
| Organization settings | settings jsonb | — | — | — | MISSING |
| Organization UI screens | — | — | — | — | MISSING |

## 3. Project Management

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| Project CRUD | projects | RLS | ProjectsScreen, CreateProject, ProjectDetail | Unit | IMPLEMENTED |
| Project categories | project_category enum | — | Category picker | Unit | IMPLEMENTED |
| Project members | project_members | RLS | — | RLS | PARTIALLY IMPLEMENTED |
| Roles (owner/admin/developer/viewer) | project_role enum | RLS helpers | — | RLS | PARTIALLY IMPLEMENTED |
| Project invitations | — | — | — | — | MISSING |
| Project duplication | — | — | — | — | MISSING |
| Project templates | — | — | — | — | MISSING |
| Project images | image_url column | — | — | — | MISSING |
| Project search/filter | — | — | ProjectsScreen (uncommitted) | — | PARTIALLY IMPLEMENTED |
| Project settings | settings jsonb | — | — | — | MISSING |

## 4. Device Management

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| Device CRUD | devices | RLS | DevicesScreen, AddDevice, DeviceDetail | Unit | IMPLEMENTED |
| Device credentials | device_credentials | device-auth Edge Function | — | — | IMPLEMENTED |
| Hardware platform selection | hardware_platform enum | — | AddDeviceScreen | Unit | IMPLEMENTED |
| Device groups | device_groups, device_group_members | RLS | — | — | PARTIALLY IMPLEMENTED |
| Online/offline detection | is_online, last_seen_at | telemetry-ingest updates | DeviceStatusIndicator | — | PARTIALLY IMPLEMENTED |
| Device pairing | — | device-auth | DevicePairingScreen | — | PARTIALLY IMPLEMENTED |
| Real-time device stream | — | Supabase stream | DeviceRepository.watchDevices | — | IMPLEMENTED |
| Device commands | device_commands | device-command Edge Function | — | — | PARTIALLY IMPLEMENTED |
| Command acknowledgement | command_results | — | — | — | PARTIALLY IMPLEMENTED |
| Device rename/edit | devices | RLS | — | — | MISSING |
| Device sharing/transfer | — | — | — | — | MISSING |
| Device export/import | — | — | — | — | MISSING |
| Device logs/diagnostics | — | — | — | — | MISSING |

## 5. Sensor & Actuator System

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| Sensor definitions table | sensor_definitions | RLS + consistency trigger | — | RLS | PARTIALLY IMPLEMENTED |
| Actuator definitions table | actuator_definitions | RLS + consistency trigger | — | RLS | PARTIALLY IMPLEMENTED |
| Sensor type enum (24 types) | sensor_type | — | — | — | IMPLEMENTED |
| Actuator type enum (16 types) | actuator_type | — | — | — | IMPLEMENTED |
| Control type enum | control_type | — | — | — | IMPLEMENTED |
| Threshold configuration | threshold columns | — | — | — | PARTIALLY IMPLEMENTED |
| Calibration | calibration jsonb | — | — | — | PARTIALLY IMPLEMENTED |
| Sensor management UI | — | — | — | — | MISSING |
| Actuator management UI | — | — | — | — | MISSING |
| Custom sensor creation | — | — | — | — | MISSING |

## 6. Telemetry & Data

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| Telemetry storage | telemetry table | telemetry-ingest | — | RLS | IMPLEMENTED |
| Rate limiting | check_telemetry_rate_limit | telemetry-ingest | — | RLS | IMPLEMENTED |
| Retention cleanup | cleanup_old_telemetry function | — | — | RLS | IMPLEMENTED |
| Telemetry ingestion API | — | telemetry-ingest Edge Function | — | — | IMPLEMENTED |
| Real-time telemetry display | — | — | — | — | MISSING |
| Historical charts | — | — | — | — | MISSING |
| Data export (CSV/JSON) | — | — | — | — | MISSING |
| Telemetry aggregation | — | — | — | — | MISSING |

## 7. Dashboard System

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| Dashboard table | dashboards | RLS | — | — | PARTIALLY IMPLEMENTED |
| Widget table (24 types) | dashboard_widgets | RLS | — | — | PARTIALLY IMPLEMENTED |
| Widget type enum | widget_type | — | — | — | IMPLEMENTED |
| Dashboard editor UI | — | — | — | — | MISSING |
| Widget drag/resize | — | — | — | — | MISSING |
| Widget data binding | — | — | — | — | MISSING |
| Dashboard templates | — | — | — | — | MISSING |
| Dashboard import/export | — | — | — | — | MISSING |

## 8. Automation Engine

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| Automation CRUD | automations | RLS | AutomationsScreen, CreateAutomation | Unit | IMPLEMENTED |
| Trigger definitions | automation_triggers | RLS | — | — | PARTIALLY IMPLEMENTED |
| Condition definitions | automation_conditions | RLS | — | — | PARTIALLY IMPLEMENTED |
| Action definitions | automation_actions | RLS | — | — | PARTIALLY IMPLEMENTED |
| Execution tracking | automation_executions | RLS | — | — | IMPLEMENTED |
| Sensor threshold evaluation | — | automation-engine | — | — | IMPLEMENTED |
| Cooldown enforcement | cooldown_seconds | automation-engine | — | — | IMPLEMENTED |
| Rate limit (per hour) | max_executions_per_hour | automation-engine | — | — | IMPLEMENTED |
| **Action dispatch (MQTT/notification/webhook)** | — | — | — | — | **MISSING** |
| Visual rule builder | — | — | — | — | MISSING |
| Schedule triggers | schedule type in enum | — | — | — | MISSING |
| Webhook triggers | webhook type + handler | webhook-handler | — | — | PARTIALLY IMPLEMENTED |
| Automation templates | — | — | — | — | MISSING |
| Automation history UI | — | — | — | — | MISSING |

## 9. AI Assistant

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| Claude Bedrock integration | — | ai-assistant Edge Function | — | — | IMPLEMENTED |
| Grok xAI integration | — | ai-assistant Edge Function | — | — | IMPLEMENTED |
| Provider selection | — | ai-assistant | AiProvider enum | — | IMPLEMENTED |
| Conversation persistence | ai_conversations, ai_messages | ai-assistant | AiRepository | — | IMPLEMENTED |
| Project context injection | — | ai-assistant | AiChatNotifier | — | IMPLEMENTED |
| Chat UI | — | — | AiAssistantScreen | — | IMPLEMENTED |
| Conversation history | — | ai-assistant | AiChatNotifier.loadConversation | — | IMPLEMENTED |
| Streaming responses | — | — | — | — | MISSING |
| Tool/function calling | tool_calls column | — | — | — | MISSING |
| AI-generated automations | — | — | — | — | MISSING |
| Token/cost tracking | tokens_used column | — | — | — | MISSING |
| Usage limits | — | — | — | — | MISSING |

## 10. Integrations

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| Integration table | integrations | RLS | — | — | PARTIALLY IMPLEMENTED |
| Integration events | integration_events | RLS | — | — | PARTIALLY IMPLEMENTED |
| Webhook integration | — | webhook-handler | — | — | IMPLEMENTED |
| Alexa Smart Home | — | skill.json manifest | — | — | PLACEHOLDER |
| Google Home | — | — | — | — | PLACEHOLDER |
| Home Assistant | — | — | — | — | PLACEHOLDER |
| IFTTT-compatible webhooks | — | webhook-handler (partial) | — | — | PARTIALLY IMPLEMENTED |
| Integration management UI | — | — | — | — | MISSING |

## 11. Notifications

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| Notification storage | notifications | RLS | NotificationsScreen | Unit | IMPLEMENTED |
| Mark read/unread | — | RLS | NotificationRepository | — | IMPLEMENTED |
| Mark all read | — | RLS | NotificationRepository | — | IMPLEMENTED |
| Notification preferences | notification_preferences | RLS | — | — | PARTIALLY IMPLEMENTED |
| Push notifications (FCM) | — | — | — | — | MISSING |
| Email notifications | — | — | — | — | MISSING |
| Notification provider | — | — | — | — | MISSING |

## 12. Scenes

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| Scene table | scenes | RLS | — | Unit | PARTIALLY IMPLEMENTED |
| Scene actions | scene_actions | RLS | — | — | PARTIALLY IMPLEMENTED |
| Scene activation | — | — | — | — | MISSING |
| Scene UI | — | — | — | — | MISSING |

## 13. Firmware & OTA

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| NexlozaClient SDK | — | — | — | — | IMPLEMENTED |
| ESP32 examples (7) | — | — | — | — | IMPLEMENTED |
| ESP8266 examples (2) | — | — | — | — | IMPLEMENTED |
| Device Studio (code generator) | — | — | DeviceStudioScreen | — | PARTIALLY IMPLEMENTED |
| Board definitions (4 boards) | — | — | Boards class | — | IMPLEMENTED |
| Sensor definitions (5 sensors) | — | — | Sensors class | — | IMPLEMENTED |
| Actuator definitions (4 actuators) | — | — | Actuators class | — | IMPLEMENTED |
| Firmware version table | firmware_versions | RLS | — | — | PARTIALLY IMPLEMENTED |
| OTA deployment table | ota_deployments | RLS | — | — | PARTIALLY IMPLEMENTED |
| OTA update delivery | — | — | — | — | MISSING |
| Arduino IDE tutorials | — | — | — | — | MISSING |

## 14. MQTT Communication

| Feature | DB | Backend | Flutter | Tests | Status |
|---|---|---|---|---|---|
| MQTT service class | — | — | MqttService | — | IMPLEMENTED |
| MQTT topic builder | — | — | MqttService.buildTopic | — | IMPLEMENTED |
| MQTT constants | — | — | MqttConstants | Unit | IMPLEMENTED |
| EMQX broker config | — | emqx.conf | — | — | IMPLEMENTED |
| EMQX ACL rules | — | acl.conf | — | — | IMPLEMENTED |
| Docker EMQX setup | — | docker-compose.yml | — | — | IMPLEMENTED |
| TLS support | — | emqx.conf (listener defined) | MqttService | — | PARTIALLY IMPLEMENTED |
| MQTT-to-Supabase bridge | — | — | — | — | **MISSING** |
| Device heartbeat handling | — | — | — | — | MISSING |
| Command delivery via MQTT | — | — | — | — | **MISSING** |

## 15. Infrastructure & DevOps

| Feature | Status |
|---|---|
| Docker Compose (full stack) | IMPLEMENTED |
| GitHub Actions CI (5 jobs) | IMPLEMENTED |
| .env.example | IMPLEMENTED |
| Setup script | IMPLEMENTED |
| Secret scanning in CI | MISSING |
| Dependency auditing in CI | MISSING |
| PlatformIO compilation in CI | MISSING |
| Deployment guide | MISSING |

## 16. Documentation

| Document | Status |
|---|---|
| README.md | IMPLEMENTED (license text wrong) |
| ARCHITECTURE.md | IMPLEMENTED |
| LICENSE (Apache 2.0) | IMPLEMENTED |
| SECURITY.md | IMPLEMENTED |
| CONTRIBUTING.md | IMPLEMENTED (license text wrong) |
| CODE_OF_CONDUCT.md | IMPLEMENTED |
| CHANGELOG.md | PARTIALLY IMPLEMENTED (stale) |
| docs/architecture/database.md | IMPLEMENTED |
| docs/architecture/security.md | IMPLEMENTED |
| docs/api/mqtt-protocol.md | IMPLEMENTED |
| docs/setup/local-development.md | IMPLEMENTED |
| docs/VALIDATION_REPORT.md | IMPLEMENTED |
| THIRD_PARTY_NOTICES.md | MISSING |
| docs/INSTALLATION.md | MISSING |
| docs/API.md | MISSING |
| docs/ARDUINO_GUIDE.md | MISSING |
| docs/ESP32_GUIDE.md | MISSING |
| docs/ESP8266_GUIDE.md | MISSING |
| docs/ALEXA_SETUP.md | MISSING |
| docs/GOOGLE_HOME_SETUP.md | MISSING |
| docs/AI_SETUP.md | MISSING |
| docs/DEPLOYMENT.md | MISSING |
| docs/TROUBLESHOOTING.md | MISSING |

---

## Summary Counts

| Status | Count |
|---|---|
| IMPLEMENTED | 62 |
| PARTIALLY IMPLEMENTED | 34 |
| MISSING | 58 |
| PLACEHOLDER | 4 |
| BLOCKED | 0 |
| VERIFIED | 0 |
