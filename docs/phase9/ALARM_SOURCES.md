# Phase 9 — Alarm Sources

NEXLOZA supports 9 alarm source types. Each source generates alarms through a different mechanism.

## 1. sensor_threshold

Triggered when a sensor value crosses a configured threshold.

- Configured via `alarm_configurations` table
- Supports operators: gt, gte, lt, lte, eq, neq, between, outside
- Supports hysteresis (e.g. alarm at 80, clear at 75)
- Supports debounce (ignore transient spikes) and cooldown (minimum interval between re-raises)

## 2. repeated_telemetry

Triggered when multiple consecutive telemetry readings are out of range.

- Requires a count threshold (e.g. 5 consecutive readings above limit)
- Reduces false positives from single-sample noise

## 3. device_offline

Triggered when a device's `is_online` field is false and `last_seen_at` exceeds a configurable threshold.

- Integrates with the devices table `is_online` and `last_seen_at` fields
- Useful for detecting communication failures

## 4. stale_data

Triggered when `device_twin_state.reported_at` exceeds a staleness threshold.

- Integrates with Phase 7 Digital Twin system
- Detects devices that are online but not sending data

## 5. twin_mismatch

Triggered when `device_twin_state.sync_status` is `failed` or when desired state differs from reported state beyond a configured duration.

- Integrates with Phase 7 Digital Twin system
- Detects actuator commands that were sent but never applied

## 6. actuator_failure

Triggered when a device command targeting an actuator fails or times out.

- Monitors `device_commands` status for failure patterns

## 7. virtual_device_fault

Triggered by virtual device simulation errors.

- Integrates with Phase 7 Virtual Device system
- Detects simulation profile failures or unexpected states

## 8. rule_action

Triggered by the `raiseAlarm` action node in the Phase 8 visual rule engine.

- Most flexible source — any rule graph can raise an alarm
- Supports arbitrary alarm keys, severity, title, message, category
- Deduplication via alarm_key upsert
- All alarm actions respect dry_run mode

## 9. manual

Created manually by a user through the Flutter UI.

- Used for operator-reported conditions
- Full audit trail via alarm_activity

## Source Configuration

Alarm configurations (`alarm_configurations` table) define automatic alarm generation for sources 1-7. Sources 8 (rule_action) and 9 (manual) do not use alarm_configurations — they are triggered directly.

Each configuration includes:
- Source type and sensor key
- Condition operator and threshold
- Hysteresis, debounce, and cooldown settings
- Severity and category
- Message template
- Enable/disable toggle
