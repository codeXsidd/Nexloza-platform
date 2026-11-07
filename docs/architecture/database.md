# Nexloza — Database Schema Documentation

## Overview

Nexloza uses PostgreSQL (via Supabase) with 14 migration files creating 30+ tables. All tables enforce Row Level Security (RLS) to ensure project-level data isolation.

## Schema Diagram (Key Relationships)

```
auth.users
    │
    ├── profiles (1:1)
    │
    ├── organizations ──── organization_members
    │
    ├── projects ──── project_members
    │       │
    │       ├── devices ──── device_credentials
    │       │     │          device_groups / device_group_members
    │       │     │
    │       │     ├── sensor_definitions
    │       │     ├── actuator_definitions
    │       │     ├── telemetry
    │       │     └── device_commands ──── command_results
    │       │
    │       ├── dashboards ──── dashboard_widgets
    │       │
    │       ├── automations
    │       │     ├── automation_triggers
    │       │     ├── automation_conditions
    │       │     ├── automation_actions
    │       │     └── automation_executions
    │       │
    │       ├── scenes ──── scene_actions
    │       │
    │       ├── notifications
    │       │
    │       ├── integrations ──── integration_events
    │       │
    │       └── audit_logs
    │
    ├── ai_conversations ──── ai_messages
    │
    └── notification_preferences
```

## Tables

### Migration 00001: Profiles

| Table | Purpose |
|-------|---------|
| `profiles` | Extends `auth.users` with display name, avatar, phone, bio, timezone, preferences |

**Key columns**: `id` (FK → auth.users), `email`, `full_name`, `avatar_url`, `timezone`, `preferences` (JSONB)

**RLS**: Users can read and update only their own profile. Profile is auto-created via trigger on user signup.

---

### Migration 00002: Organizations

| Table | Purpose |
|-------|---------|
| `organizations` | Groups of users that can share projects |
| `organization_members` | Membership with roles |

**Roles**: `owner`, `admin`, `member`, `viewer`

**Key columns (organizations)**: `id`, `name`, `slug` (unique), `description`, `avatar_url`, `owner_id`

**Key columns (organization_members)**: `organization_id`, `user_id`, `role`, `invited_by`, `joined_at`

**RLS**: Members can view their organization. Only owners and admins can update. Only owners can delete.

---

### Migration 00003: Projects

| Table | Purpose |
|-------|---------|
| `projects` | IoT projects — the primary isolation boundary |
| `project_members` | Project membership with roles |

**Key columns (projects)**: `id`, `name`, `description`, `category`, `icon`, `organization_id` (nullable), `owner_id`, `settings` (JSONB), `is_active`

**Key columns (project_members)**: `project_id`, `user_id`, `role` (owner/admin/developer/viewer)

**RLS**: Only project members can access project data. Owner has full control. Role-based write access.

---

### Migration 00004: Devices

| Table | Purpose |
|-------|---------|
| `devices` | Registered IoT devices |
| `device_credentials` | API key + secret pairs for device authentication |
| `device_groups` | Logical grouping of devices within a project |
| `device_group_members` | Device-to-group membership |

**Key columns (devices)**: `id`, `project_id`, `name`, `device_type`, `hardware_platform` (enum: esp32, esp8266, raspberry_pi, arduino, generic_mqtt, other), `firmware_version`, `mac_address`, `is_online`, `last_seen_at`, `metadata` (JSONB)

**Key columns (device_credentials)**: `device_id`, `api_key` (unique), `secret_hash`, `is_active`, `expires_at`

**RLS**: Inherited from project membership — only members of the device's project can access it.

---

### Migration 00005: Sensors & Actuators

| Table | Purpose |
|-------|---------|
| `sensor_definitions` | Sensor metadata, thresholds, calibration |
| `actuator_definitions` | Actuator metadata, control types, state |

**Sensor types** (enum): temperature, humidity, pressure, gas, smoke, motion, ultrasonic, water_level, soil_moisture, light, sound, vibration, current, voltage, energy, gps, air_quality, custom

**Actuator types** (enum): relay, light, fan, pump, motor, servo, buzzer, switch, smart_plug, custom

**Control types** (enum): toggle, slider, numeric, multi_level, color

**Key columns (sensor_definitions)**: `device_id`, `project_id`, `name`, `sensor_type`, `unit`, `telemetry_key`, `sampling_interval_ms`, `calibration` (JSONB), `min_value`, `max_value`, `warning_threshold_low/high`, `critical_threshold_low/high`

**RLS**: Inherited from project membership.

---

### Migration 00006: Telemetry & Commands

| Table | Purpose |
|-------|---------|
| `telemetry` | Time-series sensor readings |
| `device_commands` | Commands sent to devices |
| `command_results` | Acknowledgements from devices |

**Key columns (telemetry)**: `id` (bigserial), `device_id`, `sensor_key`, `value_numeric`, `value_text`, `value_json` (JSONB), `recorded_at`, `received_at`

**Indexes**: `(device_id, sensor_key, recorded_at DESC)` for efficient time-range queries

**Command statuses** (enum): pending, sent, acknowledged, executed, failed, timeout

**RLS**: Project members can read telemetry for devices in their projects. Commands require developer+ role.

---

### Migration 00007: Dashboards

| Table | Purpose |
|-------|---------|
| `dashboards` | User-created dashboard layouts |
| `dashboard_widgets` | Individual widgets with position, config, data binding |

**Widget types** (enum): button, switch, slider, gauge, circular_progress, temperature, humidity, numeric_value, line_chart, bar_chart, pie_chart, historical_graph, map, device_status, battery, text_display, led_indicator, alarm, joystick, rgb_picker, schedule, camera, custom

**Key columns (dashboard_widgets)**: `dashboard_id`, `widget_type`, `title`, `config` (JSONB — position x/y, width/height, data source, display options), `sort_order`

**RLS**: Project members can view. Developer+ can create/update/delete.

---

### Migration 00008: Automations

| Table | Purpose |
|-------|---------|
| `automations` | Automation rules with enable/disable, cooldown, rate limiting |
| `automation_triggers` | What starts an automation |
| `automation_conditions` | Conditions that must be met |
| `automation_actions` | What happens when triggered |
| `automation_executions` | Execution history and audit trail |

**Trigger types**: sensor_threshold, device_state_change, schedule, time, webhook, manual, device_online, device_offline

**Condition types**: value_comparison, time_window, device_status, compound_and, compound_or

**Action types**: device_command, notification, email, webhook, run_scene, run_automation, ai_recommendation

**Execution statuses**: running, completed, failed, cancelled

**RLS**: Project members can view. Developer+ can manage. Automation engine uses service role for execution.

---

### Migration 00009: Scenes

| Table | Purpose |
|-------|---------|
| `scenes` | Reusable multi-device state presets |
| `scene_actions` | Individual device actions within a scene |

**RLS**: Project members can view and execute. Developer+ can create/modify.

---

### Migration 00010: Notifications

| Table | Purpose |
|-------|---------|
| `notifications` | In-app notifications for users |
| `notification_preferences` | Per-category notification settings |

**Categories**: device, automation, security, system, alert

**Severity levels**: info, warning, critical

**RLS**: Users can only see their own notifications and preferences.

---

### Migration 00011: Integrations

| Table | Purpose |
|-------|---------|
| `integrations` | Third-party service connections |
| `integration_events` | Event log for integration activity |

**Integration types**: alexa, google_home, webhook, mqtt_bridge, custom

**RLS**: Project admin+ can manage integrations.

---

### Migration 00012: AI Conversations

| Table | Purpose |
|-------|---------|
| `ai_conversations` | Chat sessions with the AI assistant |
| `ai_messages` | Individual messages in a conversation |

**Message roles**: user, assistant, system, tool

**RLS**: Users can only access their own conversations.

---

### Migration 00013: Audit Logs

| Table | Purpose |
|-------|---------|
| `audit_logs` | Security and change audit trail |

**Key columns**: `user_id`, `project_id`, `action`, `resource_type`, `resource_id`, `details` (JSONB), `ip_address`

**Index**: `(project_id, created_at DESC)`

**RLS**: Project admin+ can view audit logs. Service role writes.

---

### Migration 00014: Firmware & OTA

| Table | Purpose |
|-------|---------|
| `firmware_versions` | Firmware binary metadata |
| `ota_deployments` | OTA update tracking per device/group |

**Deployment statuses**: pending, downloading, installing, completed, failed, rolled_back

**RLS**: Project developer+ can manage firmware. Devices read via service role.

## Common Patterns

### Timestamps
All tables include `created_at timestamptz default now()`. Mutable tables also include `updated_at` with an auto-update trigger.

### UUIDs
All primary keys use `uuid` (generated by `gen_random_uuid()`), except `telemetry` and `audit_logs` which use `bigserial` for insert performance.

### JSONB
Used for flexible schema fields: `config`, `metadata`, `preferences`, `payload`, `details`, `calibration`. Always validated at the application layer before storage.

### Soft Deletes
Not used — records are hard-deleted with cascading foreign keys. Audit logs preserve the history of deleted resources.
