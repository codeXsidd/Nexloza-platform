# NEXLOZA Technical Debt

**Date:** 2026-11-09
**Commit:** 637623e

---

## Critical (Must fix before release)

### TD-001: MQTT Topic Structure Mismatch
- **Flutter app** uses `nexloza/{orgId}/{projectId}/{deviceId}/{channel}`
- **Firmware SDK** uses `nexloza/{projectId}/{deviceId}/{channel}` (no org_id)
- **Master prompt** requires `nexloza/v1/{tenant_id}/{project_id}/{device_id}/{channel}`
- **Impact:** Devices and app cannot communicate via MQTT until aligned
- **Fix:** Unify all three to the v1 topic format

### TD-002: NanoMQ Not Configured
- EMQX 5.8.3 is the only broker configured (Docker, tests, docs)
- Master prompt requires NanoMQ as primary broker
- **Impact:** Architecture mismatch with requirements
- **Fix:** Add NanoMQ Docker service, create broker abstraction layer, keep EMQX as optional

### TD-003: automation-engine Notification Bug
- Edge Function sets `user_id: null` when creating notifications
- `notifications.user_id` has NOT NULL constraint
- **Impact:** Notification dispatch always fails with constraint violation
- **Fix:** Set user_id to project owner or specific recipient

### TD-004: Bedrock SigV4 Not Implemented
- ai-assistant Edge Function's Bedrock path sends unsigned requests
- AWS will reject with 403
- **Impact:** Claude Bedrock integration non-functional
- **Note:** Per master prompt, Bedrock should NOT be in runtime. Remove Bedrock code path entirely, keep Grok only.

### TD-005: Firmware TLS Insecure
- NexlozaClient.cpp calls `setInsecure()` disabling certificate verification
- **Impact:** MQTT connections vulnerable to MITM attacks
- **Fix:** Add CA certificate provisioning, document the requirement

## High (Should fix before production use)

### TD-006: 14 Database Tables Without Dart Repositories
- automation_triggers, automation_conditions, automation_actions, automation_executions, command_results, device_groups, device_group_members, firmware_versions, integration_events, notification_preferences, ota_deployments, project_members, scene_actions, audit_logs
- **Impact:** Features like visual automation builder, device grouping, scene actions, OTA cannot be built
- **Fix:** Create Dart repositories, entities, and providers for each

### TD-007: No Real-Time MQTT Data in Dashboard Widgets
- Dashboard widgets have no MQTT subscription binding
- Telemetry data not flowing to widget display
- **Impact:** Dashboards show no live device data
- **Fix:** Wire mqttMessagesProvider to dashboard widget providers

### TD-008: webhook-handler Executions Never Completed
- Creates automation_executions with status `running` but never updates to `completed`
- **Impact:** Execution history shows all webhook automations as perpetually running
- **Fix:** Add status update after action processing

### TD-009: Device Commands Not Delivered via MQTT
- device-command Edge Function inserts into DB but doesn't publish to MQTT
- Devices poll or never receive commands
- **Impact:** Real-time device control not working
- **Fix:** Add MQTT publish to Edge Function or create a bridge service

### TD-010: Firmware SDK License Mismatch
- library.json says MIT, project root LICENSE is Apache 2.0
- **Impact:** License confusion for SDK users
- **Fix:** Change library.json to Apache-2.0

## Medium (Improve before public release)

### TD-011: Tests Hit OOM on Low-Memory Machines
- `flutter test` crashes with "Out of memory" on some runs
- 223 tests pass when memory available
- **Fix:** Split test files or run with `--concurrency=1`

### TD-012: EMQX Default Password in Docker Compose
- `nexloza_mqtt_2024` as default in environment section
- **Fix:** Remove default, require .env configuration

### TD-013: CORS Wildcard in All Edge Functions
- All 6 Edge Functions allow `Access-Control-Allow-Origin: *`
- **Fix:** Restrict to app domain in production

### TD-014: No User-Level API Keys Table
- Only device_credentials exists; no table for REST API access tokens
- **Fix:** Create api_keys migration

### TD-015: Missing Tables
- `usage_records` (AI quota tracking)
- `device_events` (connection/error log)
- **Fix:** Create migrations

## Low (Nice to have)

### TD-016: Device Credential Hashing
- SHA-256 used, bcrypt/argon2 recommended for production
- Current approach is acceptable for IoT device auth

### TD-017: No Pagination in List Screens
- Most list screens load all records
- Acceptable at current scale, needs pagination for 100+ items

### TD-018: CI Missing Several Checks
- No secret scanning, dependency audit, PlatformIO compilation, RLS tests, integration tests
- **Fix:** Add to ci.yml incrementally
