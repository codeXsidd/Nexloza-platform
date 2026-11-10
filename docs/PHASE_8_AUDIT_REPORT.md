# NEXLOZA — Phase 8 Audit Report

## Visual Rule Engine and Advanced Automation

**Date:** 2026-11-10
**Auditor:** Claude (automated audit)
**Starting commit:** 27baded (Phase 7)
**Branch:** main (up to date with origin/main)

---

## 1. Repository State

| Item | Status |
|------|--------|
| Branch | main |
| HEAD | 27baded — Phase 7: Virtual Devices and Digital Twin System |
| Working tree | Clean |
| Remote | origin/main — up to date |
| Test baseline | 492 passing |
| Analyzer | 0 issues |
| Migrations | 00001–00018 present |

---

## 2. Existing Automation Architecture

### Database Schema (migration 00008)

Tables:
- `automations` — project_id, name, description, is_enabled, priority, cooldown_seconds, max_executions_per_hour, last_executed_at, execution_count
- `automation_triggers` — automation_id FK, trigger_type ENUM, config JSONB, is_active
- `automation_conditions` — automation_id FK, condition_type ENUM, config JSONB, sort_order
- `automation_actions` — automation_id FK, action_type ENUM, config JSONB, sort_order, delay_seconds
- `automation_executions` — automation_id FK, trigger_id FK, trigger_data JSONB, status ENUM, started_at, completed_at, error_message, actions_executed JSONB, duration_ms

Enums:
- `trigger_type`: sensor_threshold, device_state_change, schedule, time, webhook, manual, device_online, device_offline
- `condition_type`: value_comparison, time_window, device_status, compound_and, compound_or
- `action_type`: device_command, notification, email, webhook, run_scene, run_automation, ai_recommendation
- `execution_status`: running, completed, failed, cancelled

RLS: All tables protected via `is_project_member()` / `can_modify_project()`.

### Edge Function: automation-engine

The existing `automation-engine` Edge Function:
- Accepts authenticated requests with device_id, sensor_key, value
- Queries enabled automations with matching sensor_threshold triggers
- Evaluates comparison operators: gt, lt, eq, gte, lte, between
- Checks cooldown and max_executions_per_hour
- Executes actions: device_command (inserts device_commands row), notification (inserts notifications row)
- Records execution in automation_executions with actions_executed array
- Updates automation execution_count and last_executed_at

**Limitations of existing engine:**
- Only evaluates sensor_threshold trigger type
- Flat trigger→action model (no graph traversal)
- No condition evaluation (conditions table exists but is unused by the engine)
- No correlation IDs or execution depth tracking
- No loop prevention
- No dry-run mode
- No versioning or publish lifecycle
- No Digital Twin integration
- No device online/offline trigger evaluation

### Flutter Implementation

- `AutomationRepository`: CRUD for automations table
- `AutomationsNotifier`: AsyncNotifier with create/toggle/delete
- `AutomationsScreen`: List with enable/disable toggle, delete
- `CreateAutomationScreen`: Form with project selector, trigger type dropdown, action type dropdown — stores description text only (no actual trigger/condition/action config)
- `AutomationDetailScreen`: Shows status, config display (cooldown, max/hr, priority), description

**Assessment:** The current Flutter automation screens are scaffolding — they create automation records with name/description but do not configure actual trigger conditions, actions, or the engine. The rule engine Phase 8 will extend these into a full visual builder.

---

## 3. Scene Architecture (migration 00009)

- `scenes` table: project_id, name, description, icon, is_active
- `scene_actions` table: scene_id, device_id, actuator_id, action_type, target_state JSONB, sort_order, delay_ms
- `SceneRepository` with CRUD + `activateScene()` (calls automation-engine)
- RLS protected

---

## 4. Device Command Architecture (migration 00006)

- `device_commands` table: device_id, issued_by, command_type, payload JSONB, status (pending→sent→acknowledged→executed→failed→timeout), retry_count, max_retries, expires_at
- `command_results` table: command_id, device_id, success, result_data JSONB
- `device-command` Edge Function: JWT auth → validates device access → inserts command → returns MQTT topic
- MQTT topic: `nexloza/v1/{org}/{project}/{device}/command`

---

## 5. Telemetry Architecture (migration 00006)

- `telemetry` table: device_id, sensor_key, value_numeric/value_text/value_json, recorded_at
- `telemetry-ingest` Edge Function: API key + secret auth with constant-time hash comparison, rate limiting, bulk insert
- Phase 7 `TelemetryPublisher`: bridges SimulatorEngine → MQTT + Supabase telemetry

---

## 6. Digital Twin Architecture (migration 00018)

- `device_twin_state` table: device_id (unique FK), reported_state JSONB, desired_state JSONB, reported_version, desired_version, sync_status (synced/pending/failed/stale), last_sync_at
- `DigitalTwinRepository`: getState, createState, updateReported (merge + auto-sync detection), updateDesired (optimistic concurrency), setSyncStatus, watchState (Supabase Realtime)

---

## 7. MQTT Architecture

- NanoMQ broker (emqx/nanomq:0.22.6-slim)
- Topic contract: `nexloza/v1/{organization_id}/{project_id}/{device_id}/{channel}`
- Channels: telemetry, command, command-ack, state, status, config
- `MqttService`: connect, subscribe, publish, disconnect with auto-reconnect
- `MqttConstants`: topic builders for all channels

---

## 8. Phase 8 Design Decisions

### Extend vs. Replace

**Decision: Extend the existing automation schema and engine.**

Rationale:
- The `automations` table already has project_id, is_enabled, cooldown_seconds, max_executions_per_hour, execution_count — all needed by Phase 8
- The `automation_executions` table provides the execution history foundation
- The `automation-engine` Edge Function is the execution entry point — extend it with graph evaluation
- Existing trigger/condition/action enums align with Phase 8 node types
- RLS policies already protect all automation tables

### Architecture

1. **Rule graph stored in `automations.rule_graph JSONB`** — the graph is the source of truth for visual rules
2. **Rule lifecycle via `automations.status TEXT`** — draft/validated/published/enabled/disabled/archived
3. **Published snapshots in `rule_versions` table** — immutable copies for execution safety
4. **Event inbox via `rule_events` table** — durable queue for async processing with deduplication
5. **Extended `automation_executions`** — add correlation_id, execution_depth, node_results for tracing
6. **Extended `automation-engine` Edge Function** — graph evaluator with loop prevention, all node types, dry-run mode
7. **Visual editor in Flutter** — canvas with InteractiveViewer, CustomPainter connections, typed nodes

### What NOT to Add

- No Kafka, Redis, or second broker
- No separate MQTT pipeline
- No arbitrary user code execution
- No alarm/notification platform (Phase 9)
- No AI rule generation
- No edge computing

---

## 9. Files to Preserve

All existing files must be preserved. Key integration points:
- `app/lib/features/automations/` — extend, don't replace
- `backend/supabase/functions/automation-engine/` — extend
- `app/lib/features/virtual_devices/` — reuse for dry-run
- `app/lib/features/dashboards/` — reuse DataSource/TelemetryDataService
- All migrations 00001–00018 — do not modify
