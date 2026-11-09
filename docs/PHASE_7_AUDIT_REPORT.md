# Phase 7 Audit Report — Virtual Devices and Digital Twin System

**Date:** 2026-11-09
**Auditor:** Claude (automated)
**Starting commit:** `5c2dd10` (Phase 6)

---

## Repository State

| Check | Result |
|-------|--------|
| Branch | `main` |
| HEAD commit | `5c2dd10` — Phase 6 |
| Remote tracking | Up to date with `origin/main` |
| Unstaged changes | `docs/PHASE_6_COMPLETION_REPORT.md` content update (not code) |
| Flutter analyzer | 0 issues |
| Flutter tests | 403 passing, 0 failures |
| Latest migration | `00017_dashboard_phase6.sql` |

## Existing Architecture Relevant to Phase 7

### Device Management

- **Table:** `public.devices` — `id`, `project_id`, `name`, `device_type`, `hardware_platform` (enum: esp32, esp8266, raspberry_pi, arduino, generic_mqtt, other), `firmware_version`, `mac_address`, `is_online`, `last_seen_at`, `metadata` (JSONB), `tags`
- **Flutter entity:** `Device` class with `HardwarePlatform` enum
- **Repository:** `DeviceRepository` — CRUD + `provisionCredentials()` + `watchDevices()`
- **Credentials:** `device_credentials` table with `api_key`, `secret_hash`, `is_active`
- **RLS:** Project member can view, developer+ can modify

### Sensor/Actuator Definitions

- **Sensors:** `sensor_definitions` with `device_id`, `project_id`, `sensor_type` (enum), `telemetry_key`, `unit`, `min_value`, `max_value`, thresholds
- **Actuators:** `actuator_definitions` with `actuator_type` (enum), `control_type` (enum), `command_key`, `min_value`, `max_value`, `step`, `current_state` (JSONB)
- **Flutter entities:** `SensorDefinition`, `ActuatorDefinition` with full fromJson/toJson
- **Repositories:** `SensorRepository`, `ActuatorRepository`

### Telemetry Pipeline

- **Edge Function:** `telemetry-ingest` — authenticates via `x-api-key`/`x-api-secret`, validates secret hash (constant-time), rate limits, inserts to `telemetry` table
- **Table:** `telemetry` — `device_id`, `sensor_key`, `value_numeric`/`value_text`/`value_json`, `recorded_at`
- **Flutter service:** `TelemetryDataService` — reference-counted Supabase Realtime subscriptions, `getHistory()`, `getLatest()`

### Command Pipeline

- **Edge Function:** `device-command` — authenticates user, verifies device access via RLS, creates `device_commands` row, returns MQTT topic for publish
- **Table:** `device_commands` — `device_id`, `command_type`, `payload`, `status` (enum: pending/sent/acknowledged/executed/failed/timeout), timestamps, retry tracking
- **Flutter:** `CommandRepository` invokes Edge Function then publishes to MQTT

### MQTT Architecture

- **Broker:** NanoMQ (emqx/nanomq:0.22.6-slim)
- **Topic contract:** `nexloza/v1/{org_id}/{project_id}/{device_id}/{channel}`
- **Channels:** telemetry, command, command-ack, state, status, config
- **Flutter service:** `MqttService` with connect, subscribe, publish, auto-reconnect
- **Constants:** `MqttConstants` with topic builder helpers and QoS levels

### Device Auth Flow

- **Edge Function:** `device-auth` — validates API key + secret hash, returns device info + MQTT topic map with scoped topics
- **MQTT identity:** `client_id: nexloza_{device_id}`, `username: {device_id}`

### Dashboard Integration (Phase 6)

- **Widget registry:** 42 widget types, plugin-based `WidgetRegistry` singleton
- **Data binding:** `DataSource` model → `DataSourceSelector` (cascading dropdowns)
- **Telemetry display:** `TelemetryDataService` feeds `WidgetDataState` to renderers
- **Screens:** Dashboard list, create (with templates), editor (grid + config)

### Navigation

- **Router:** GoRouter with `StatefulShellRoute` for main nav + standalone routes
- **Route names:** `RouteNames` abstract class
- **Existing device routes:** `/devices`, `/devices/add`, `/devices/:id`, `/devices/:id/edit`, `/devices/:id/sensors`, `/devices/:id/actuators`

## What Does Not Exist Yet

- No `is_virtual` flag or virtual device marker in the `devices` table
- No simulation profile definitions
- No digital twin state table or service
- No simulator engine
- No virtual device screens in Flutter
- No fault scenario system

## Migration Strategy

The existing `devices` table and `hardware_platform` enum can accommodate virtual devices by:

1. Adding `is_virtual BOOLEAN DEFAULT false` to `devices` — cleanly separates virtual from physical
2. Adding `simulation_profile TEXT` to `devices` — stores which profile template was used
3. Creating `device_twin_state` table for desired/reported state tracking
4. Virtual devices use `hardware_platform = 'generic_mqtt'` (not esp32/esp8266)

This approach reuses the existing provisioning, credential, sensor, actuator, telemetry, and command infrastructure without modification.

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Virtual devices visible as physical | `is_virtual` flag + UI indicators |
| Simulator floods telemetry | Configurable intervals + bounded timers |
| Twin state conflicts | Version counter + timestamp comparison |
| Credential leakage | Same device-auth flow, no shortcuts |
| Test baseline regression | Run full suite after each layer |
