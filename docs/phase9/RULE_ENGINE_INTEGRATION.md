# Phase 9 — Rule Engine Integration

## New Action Nodes

Phase 9 adds 4 alarm action nodes to the Phase 8 visual rule engine, bringing the total to 39 node types.

### raiseAlarm

Raises or re-raises an alarm with deduplication.

| Config Key | Required | Description |
|-----------|----------|-------------|
| alarm_key | Yes | Stable key for deduplication |
| severity | Yes | critical / high / medium / warning / informational |
| title | Yes | Human-readable alarm title |
| message | No | Detail message |
| category | No | Grouping category (e.g., "temperature") |

**Behavior:**
- If no active/acknowledged alarm exists with this key in the project, a new alarm is created with `source = 'rule_action'`.
- If an alarm already exists, its `occurrence_count` is incremented and `last_occurred_at` is updated. No duplicate is created.
- If the alarm has an `escalation_policy_id`, escalation is started automatically.
- Respects `dry_run` mode — in dry run, the alarm is not actually created.

### updateAlarmSeverity

Updates the severity of an existing alarm.

| Config Key | Required | Description |
|-----------|----------|-------------|
| alarm_key | Yes | Key of alarm to update |
| severity | Yes | New severity level |

**Behavior:**
- Finds the active/acknowledged alarm by key within the project.
- Updates severity and records a `severity_changed` activity entry.
- No-op if no matching alarm is found.

### clearAlarm

Clears an active or acknowledged alarm.

| Config Key | Required | Description |
|-----------|----------|-------------|
| alarm_key | Yes | Key of alarm to clear |
| reason | No | Reason for clearing |

**Behavior:**
- Sets status to `cleared`, records `cleared_at` and `cleared_reason`.
- Cancels all pending escalation tasks for this alarm.
- Records a `cleared` activity entry.

### addAlarmComment

Adds a comment to an alarm's activity log.

| Config Key | Required | Description |
|-----------|----------|-------------|
| alarm_key | Yes | Key of alarm to comment on |
| comment | Yes | Comment text |

**Behavior:**
- Creates an `alarm_activity` entry with type `comment_added`.
- Stores the comment in the `details` JSONB field.

## Flutter Config Panel

Each new node type has a configuration panel in `node_config_panel.dart`:
- **raiseAlarm**: alarm_key, severity dropdown, title, message, category
- **updateAlarmSeverity**: alarm_key, severity dropdown
- **clearAlarm**: alarm_key, reason
- **addAlarmComment**: alarm_key, comment

## Automation Engine Extension

The `automation-engine` Edge Function (`index.ts`) was extended:
- `getNodeCategory()` includes all 4 alarm types in the `actions` array.
- `executeAction()` switch statement handles each type with full database operations.
- All actions use the execution context's `project_id` for scoping.
- All actions respect `dry_run` mode.
- Rule execution happens on the backend, not in the Flutter UI.

## Example Rule Graph

A temperature monitoring rule that raises an alarm when temperature exceeds 80°C and clears it when it drops below 75°C:

```
[sensorValueChanged] --> [greaterThan (80)] --> [raiseAlarm]
                                                  alarm_key: "temp_high:{device_id}"
                                                  severity: high
                                                  title: "Temperature High"

[sensorValueChanged] --> [lessThan (75)] --> [clearAlarm]
                                               alarm_key: "temp_high:{device_id}"
                                               reason: "Temperature returned to normal"
```

This implements hysteresis: alarm at 80, clear at 75, preventing alarm flapping around the threshold.
