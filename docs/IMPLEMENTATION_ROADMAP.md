# NEXLOZA Implementation Roadmap

**Date:** 2026-11-09
**Baseline:** 637623e — 148 Dart files, 223 tests, 33 DB tables, 6 Edge Functions
**Completion:** ~55% of master prompt requirements

---

## Current State Summary

**Done:** Authentication, profiles, organizations, projects, invitations, device CRUD, sensor/actuator CRUD, basic dashboards (6 widget types), automations CRUD, scenes CRUD, AI chat (Grok), notifications list, integrations list, analytics dashboard, settings, MQTT service, firmware SDK (10 examples), 16 migrations, 6 Edge Functions, CI/CD pipeline.

**Not Done:** NanoMQ broker, virtual device simulator, voice control, Alexa integration, Google Home integration, visual automation builder, real-time dashboard data, 16+ dashboard widget types, full Hardware Lab tutorials, offline-first with SQLite, comprehensive documentation.

---

## Phase 3: NanoMQ Infrastructure & MQTT Alignment

**Prerequisite:** None (independent)
**Estimated scope:** ~20 files

| Task | Priority |
|---|---|
| Add NanoMQ to docker-compose.yml as primary broker | Critical |
| Create broker abstraction interface | Critical |
| Unify topic structure to `nexloza/v1/{tenant}/{project}/{device}/{channel}` | Critical |
| Update Flutter MqttConstants and MqttService | Critical |
| Update firmware SDK topic format | Critical |
| Update Edge Functions topic references | Critical |
| Configure NanoMQ auth (username/password, topic ACL) | High |
| Configure NanoMQ TLS | High |
| Keep EMQX as optional alternative in docker-compose | Medium |
| Add NanoMQ health check | Medium |
| Document MQTT protocol with new topic structure | Medium |

## Phase 4: Firmware SDK Completion

**Prerequisite:** Phase 3 (topic alignment)
**Estimated scope:** ~15 files

| Task | Priority |
|---|---|
| Add registerSensor() API | High |
| Add registerActuator() API | High |
| Add sendCommand() API | High |
| Add setDeviceMetadata() API | High |
| Make heartbeat() and reconnect() public | Medium |
| Fix license to Apache 2.0 | High |
| Add TLS CA certificate support (replace setInsecure) | High |
| Add esp32-ultrasonic example | Medium |
| Add esp32-water-level example | Medium |
| Add arduino-gateway compilable sketch | Medium |

## Phase 5: Flutter App — Missing Repositories & Providers

**Prerequisite:** None (database tables exist)
**Estimated scope:** ~30 files

| Task | Priority |
|---|---|
| Dart repos for: automation_triggers, automation_conditions, automation_actions | Critical |
| Dart repos for: automation_executions | High |
| Dart repos for: device_groups, device_group_members | High |
| Dart repos for: scene_actions | High |
| Dart repos for: project_members | High |
| Dart repos for: notification_preferences | Medium |
| Dart repos for: firmware_versions, ota_deployments | Medium |
| Dart repos for: audit_logs, command_results, integration_events | Low |
| Notification provider (AsyncNotifier) | High |

## Phase 6: Dashboard Builder Enhancement

**Prerequisite:** Phase 3 (MQTT data flow)
**Estimated scope:** ~25 files

| Task | Priority |
|---|---|
| Wire MQTT data to dashboard widgets (real-time) | Critical |
| Slider widget | High |
| Button widget | High |
| Progress bar widget | High |
| LED indicator widget | High |
| Map/GPS widget | Medium |
| Terminal widget | Medium |
| Temperature/humidity card widgets | Medium |
| Historical chart widget | Medium |
| Widget resize and rearrange | Medium |
| Dashboard templates | Low |
| Import/export configuration | Low |

## Phase 7: Virtual Device Simulator

**Prerequisite:** Phase 3 (MQTT working)
**Estimated scope:** ~15 files

| Task | Priority |
|---|---|
| Virtual device entity and repository | Critical |
| Virtual device creation screen | Critical |
| Telemetry generation service (configurable intervals, ranges) | Critical |
| Virtual actuator command handler | High |
| Online/offline simulation | High |
| MQTT integration (same topics as physical devices) | Critical |
| Clear visual marking of simulated devices | High |
| Simulated device failure modes | Low |

## Phase 8: Visual Automation Builder

**Prerequisite:** Phase 5 (trigger/condition/action repos)
**Estimated scope:** ~20 files

| Task | Priority |
|---|---|
| Trigger selection UI (sensor threshold, schedule, device status) | Critical |
| Condition builder UI (comparisons, AND/OR/NOT) | Critical |
| Action selection UI (command, notification, webhook) | Critical |
| Fix automation-engine notification bug (TD-003) | Critical |
| Fix webhook-handler completion bug (TD-008) | High |
| Execution history screen | High |
| Scheduling support (cron-like) | Medium |
| Automation templates | Low |
| Loop prevention | Medium |

## Phase 9: Grok AI Enhancement

**Prerequisite:** None
**Estimated scope:** ~10 files

| Task | Priority |
|---|---|
| Remove Bedrock code path from ai-assistant Edge Function | Critical |
| Streaming response support | High |
| AI automation proposal generation | High |
| Mock AI provider for tests | High |
| API usage tracking (usage_records table) | Medium |
| BYOK (Bring Your Own Key) UI | Medium |

## Phase 10: Voice Control

**Prerequisite:** Phase 3 (MQTT), command infrastructure
**Estimated scope:** ~15 files

| Task | Priority |
|---|---|
| speech_to_text package integration | Critical |
| Push-to-talk UI | Critical |
| Intent parser (deterministic, no AI needed) | Critical |
| Device command resolution | High |
| Confirmation flow for sensitive operations | High |
| Typed command fallback | Medium |
| Voice settings screen | Medium |

## Phase 11: Alexa & Google Home

**Prerequisite:** OAuth infrastructure, HTTPS endpoint
**Estimated scope:** ~20 files

| Task | Priority |
|---|---|
| Alexa Lambda/Edge Function handler | High |
| Alexa OAuth 2.0 account linking | High |
| Alexa device discovery | High |
| Alexa PowerController | High |
| Google Home Cloud-to-Cloud handler | High |
| Google Home OAuth + account linking | High |
| Google Home SYNC/QUERY/EXECUTE | High |
| Mock request tests for both | High |
| Setup documentation | Medium |

## Phase 12: Hardware Lab Enhancement

**Prerequisite:** Phase 4 (SDK completion)
**Estimated scope:** ~15 files

| Task | Priority |
|---|---|
| Interactive step-by-step guide screens | High |
| Board-specific wiring diagram images | High |
| Arduino IDE installation guide | High |
| Library installation guide | High |
| Troubleshooting per board | Medium |
| Serial monitor testing guide | Medium |

## Phase 13: Offline-First & Notifications

**Prerequisite:** None
**Estimated scope:** ~15 files

| Task | Priority |
|---|---|
| SQLite local database (drift or sqflite) | High |
| Offline command queue with unique IDs + expiry | High |
| Connection monitoring UI | High |
| Push notifications (FCM) | High |
| Notification preferences screen | Medium |
| Data sync conflict resolution | Medium |

## Phase 14: Security & Performance

**Prerequisite:** All prior phases
**Estimated scope:** ~10 files

| Task | Priority |
|---|---|
| CORS restriction for production | High |
| NanoMQ TLS with proper certificates | High |
| Secret scanning in CI | High |
| Dependency auditing in CI | High |
| Load testing (1/10/50/100 virtual devices) | Medium |
| Telemetry batch ingestion optimization | Medium |
| Scalability report | Medium |

## Phase 15: Documentation & Release

**Prerequisite:** All prior phases
**Estimated scope:** ~20 files

| Task | Priority |
|---|---|
| INSTALLATION.md | Critical |
| DEPLOYMENT.md | Critical |
| SELF_HOSTING.md | Critical |
| THIRD_PARTY_NOTICES.md | Critical |
| ESP32_GUIDE.md, ESP8266_GUIDE.md, ARDUINO_GUIDE.md | High |
| GROK_SETUP.md | High |
| ALEXA_SETUP.md, GOOGLE_HOME_SETUP.md | High |
| VIRTUAL_DEVICE_GUIDE.md | High |
| TROUBLESHOOTING.md | High |
| API.md | Medium |
| FINAL_RELEASE_AUDIT.md | Critical |
| TEST_RESULTS.md | Critical |
| KNOWN_LIMITATIONS.md | Critical |
| SCALABILITY_REPORT.md | Medium |
| CHANGELOG.md update | High |

---

## Estimated Total Remaining Work

| Phase | Files | Status |
|---|---|---|
| Phase 3: NanoMQ & MQTT | ~20 | NOT STARTED |
| Phase 4: Firmware SDK | ~15 | NOT STARTED |
| Phase 5: Missing Repos | ~30 | NOT STARTED |
| Phase 6: Dashboard Builder | ~25 | NOT STARTED |
| Phase 7: Virtual Simulator | ~15 | NOT STARTED |
| Phase 8: Automation Builder | ~20 | NOT STARTED |
| Phase 9: Grok AI | ~10 | NOT STARTED |
| Phase 10: Voice Control | ~15 | NOT STARTED |
| Phase 11: Alexa & Google | ~20 | NOT STARTED |
| Phase 12: Hardware Lab | ~15 | NOT STARTED |
| Phase 13: Offline & Push | ~15 | NOT STARTED |
| Phase 14: Security & Perf | ~10 | NOT STARTED |
| Phase 15: Docs & Release | ~20 | NOT STARTED |
| **Total remaining** | **~230 files** | |
