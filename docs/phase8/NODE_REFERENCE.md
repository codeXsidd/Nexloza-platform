# Phase 8 — Node Type Reference

This document describes all 35 node types available in the Visual Rule Builder, organized by category.

---

## Triggers (11 types)

Trigger nodes initiate rule evaluation when a matching event arrives. Every rule graph must have exactly one trigger node.

### telemetryReceived

Fires when any telemetry data arrives from a device.

- **Required config**: `device_id`
- **Input ports**: none
- **Output ports**: `out` (event)
- **Example config**:
  ```json
  { "device_id": "550e8400-e29b-41d4-a716-446655440000" }
  ```

### sensorValueChanged

Fires when a specific sensor's value changes.

- **Required config**: `device_id`, `sensor_key`
- **Input ports**: none
- **Output ports**: `out` (number)
- **Example config**:
  ```json
  { "device_id": "550e8400-...", "sensor_key": "temperature" }
  ```

### sensorAboveThreshold

Fires when a sensor value exceeds a configured threshold.

- **Required config**: `device_id`, `sensor_key`, `threshold`
- **Input ports**: none
- **Output ports**: `out` (number)
- **Example config**:
  ```json
  { "device_id": "550e8400-...", "sensor_key": "temperature", "threshold": 30 }
  ```

### sensorBelowThreshold

Fires when a sensor value drops below a configured threshold.

- **Required config**: `device_id`, `sensor_key`, `threshold`
- **Input ports**: none
- **Output ports**: `out` (number)
- **Example config**:
  ```json
  { "device_id": "550e8400-...", "sensor_key": "humidity", "threshold": 20 }
  ```

### deviceOnlineTrigger

Fires when a device comes online.

- **Required config**: `device_id`
- **Input ports**: none
- **Output ports**: `out` (boolean)
- **Example config**:
  ```json
  { "device_id": "550e8400-..." }
  ```

### deviceOfflineTrigger

Fires when a device goes offline.

- **Required config**: `device_id`
- **Input ports**: none
- **Output ports**: `out` (boolean)
- **Example config**:
  ```json
  { "device_id": "550e8400-..." }
  ```

### deviceStatusChanged

Fires on any device status transition (online, offline, error).

- **Required config**: `device_id`
- **Input ports**: none
- **Output ports**: `out` (any)
- **Example config**:
  ```json
  { "device_id": "550e8400-..." }
  ```

### twinReportedChanged

Fires when a device's reported digital twin state changes.

- **Required config**: `device_id`, `attribute_key`
- **Input ports**: none
- **Output ports**: `out` (any)
- **Example config**:
  ```json
  { "device_id": "550e8400-...", "attribute_key": "firmware_version" }
  ```

### twinDesiredChanged

Fires when a device's desired digital twin state changes.

- **Required config**: `device_id`, `attribute_key`
- **Input ports**: none
- **Output ports**: `out` (any)
- **Example config**:
  ```json
  { "device_id": "550e8400-...", "attribute_key": "target_temperature" }
  ```

### scheduledTrigger

Fires on a cron schedule.

- **Required config**: `cron_expression`
- **Input ports**: none
- **Output ports**: `out` (event)
- **Example config**:
  ```json
  { "cron_expression": "0 */5 * * *" }
  ```

### manualTrigger

Fires when triggered manually by a user or via the dry-run tester.

- **Required config**: none
- **Input ports**: none
- **Output ports**: `out` (event)
- **Example config**: `{}`

---

## Conditions (13 types)

Condition nodes evaluate input data and produce boolean or comparison results.

### equalTo

Checks if the input value equals a configured value.

- **Required config**: `value`
- **Input ports**: `in` (any)
- **Output ports**: `out` (boolean)
- **Example config**:
  ```json
  { "value": "on" }
  ```

### notEqualTo

Checks if the input value does not equal a configured value.

- **Required config**: `value`
- **Input ports**: `in` (any)
- **Output ports**: `out` (boolean)
- **Example config**:
  ```json
  { "value": "off" }
  ```

### greaterThan

Checks if a numeric input exceeds a threshold.

- **Required config**: `value`
- **Input ports**: `in` (number)
- **Output ports**: `out` (boolean)
- **Example config**:
  ```json
  { "value": 25.5 }
  ```

### greaterThanOrEqual

Checks if a numeric input meets or exceeds a threshold.

- **Required config**: `value`
- **Input ports**: `in` (number)
- **Output ports**: `out` (boolean)
- **Example config**:
  ```json
  { "value": 100 }
  ```

### lessThan

Checks if a numeric input is below a threshold.

- **Required config**: `value`
- **Input ports**: `in` (number)
- **Output ports**: `out` (boolean)
- **Example config**:
  ```json
  { "value": 10 }
  ```

### lessThanOrEqual

Checks if a numeric input is at or below a threshold.

- **Required config**: `value`
- **Input ports**: `in` (number)
- **Output ports**: `out` (boolean)
- **Example config**:
  ```json
  { "value": 50 }
  ```

### betweenRange

Checks if a numeric input falls within a min/max range (inclusive).

- **Required config**: `min_value`, `max_value`
- **Input ports**: `in` (number)
- **Output ports**: `out` (boolean)
- **Example config**:
  ```json
  { "min_value": 18, "max_value": 26 }
  ```

### booleanCheck

Checks if a boolean input matches an expected value.

- **Required config**: `expected`
- **Input ports**: `in` (boolean)
- **Output ports**: `out` (boolean)
- **Example config**:
  ```json
  { "expected": true }
  ```

### andGate

Outputs true only if all connected inputs are true.

- **Required config**: none
- **Input ports**: `a` (boolean), `b` (boolean)
- **Output ports**: `out` (boolean)
- **Example config**: `{}`

### orGate

Outputs true if any connected input is true.

- **Required config**: none
- **Input ports**: `a` (boolean), `b` (boolean)
- **Output ports**: `out` (boolean)
- **Example config**: `{}`

### notGate

Inverts a boolean input.

- **Required config**: none
- **Input ports**: `in` (boolean)
- **Output ports**: `out` (boolean)
- **Example config**: `{}`

### deviceOnlineCheck

Queries the database to check if a device is currently online. This is an asynchronous condition that performs a DB lookup during evaluation.

- **Required config**: `device_id`
- **Input ports**: `in` (any)
- **Output ports**: `out` (boolean)
- **Example config**:
  ```json
  { "device_id": "550e8400-..." }
  ```

### twinDesiredVsReported

Compares a specific attribute between a device's desired and reported twin states. Returns true if they match.

- **Required config**: `device_id`, `attribute_key`
- **Input ports**: `in` (any)
- **Output ports**: `out` (boolean)
- **Example config**:
  ```json
  { "device_id": "550e8400-...", "attribute_key": "target_temperature" }
  ```

---

## Actions (7 types)

Action nodes perform side effects. In dry-run mode, side effects are skipped but the node still evaluates and reports what would have happened.

### sendCommand

Sends a command to a device by inserting a row into `device_commands`.

- **Required config**: `device_id`, `command_type`
- **Optional config**: `payload`
- **Input ports**: `in` (any)
- **Output ports**: `out` (any)
- **Throttling**: Max one command per device per 5 seconds within the same correlation
- **Example config**:
  ```json
  {
    "device_id": "550e8400-...",
    "command_type": "set_state",
    "payload": { "power": "off", "brightness": 0 }
  }
  ```

### setActuator

Sets a specific actuator value on a device.

- **Required config**: `device_id`, `actuator_key`, `value`
- **Input ports**: `in` (any)
- **Output ports**: `out` (any)
- **Throttling**: Max one command per device per 5 seconds within the same correlation
- **Example config**:
  ```json
  {
    "device_id": "550e8400-...",
    "actuator_key": "fan_speed",
    "value": 75
  }
  ```

### updateTwinDesired

Merges attributes into a device's desired digital twin state.

- **Required config**: `device_id`, `attributes`
- **Input ports**: `in` (any)
- **Output ports**: `out` (any)
- **Example config**:
  ```json
  {
    "device_id": "550e8400-...",
    "attributes": { "target_temperature": 22, "mode": "auto" }
  }
  ```

### executeScene

Activates a predefined scene, executing all scene actions in order.

- **Required config**: `scene_id`
- **Input ports**: `in` (any)
- **Output ports**: `out` (any)
- **Example config**:
  ```json
  { "scene_id": "660e8400-e29b-41d4-a716-446655440000" }
  ```

### recordEvent

Inserts an event record into `rule_events` for audit and alerting purposes.

- **Required config**: `event_name`
- **Optional config**: `severity` (info, warning, error, critical)
- **Input ports**: `in` (any)
- **Output ports**: `out` (any)
- **Example config**:
  ```json
  { "event_name": "high_temperature_alert", "severity": "warning" }
  ```

### logResult

Records a message in the execution trace without performing any external side effect.

- **Required config**: `message`
- **Input ports**: `in` (any)
- **Output ports**: `out` (any)
- **Example config**:
  ```json
  { "message": "Temperature check passed, proceeding to action" }
  ```

### stopFlow

Stops further execution of the current rule. Downstream nodes are skipped.

- **Required config**: none
- **Input ports**: `in` (any)
- **Output ports**: none
- **Example config**: `{}`

---

## Flow Control (4 types)

Flow control nodes manage execution paths and timing.

### conditionalBranch

Routes execution to one of two output paths based on a boolean input.

- **Required config**: none
- **Input ports**: `in` (boolean)
- **Output ports**: `true` (any), `false` (any)
- **Behavior**: If input is truthy, downstream nodes connected to the `true` port execute; nodes on the `false` branch are skipped (and vice versa)
- **Example config**: `{}`

### delay

Pauses execution for a configured duration.

- **Required config**: `duration_ms`
- **Input ports**: `in` (any)
- **Output ports**: `out` (any)
- **Constraints**: 100ms–3,600,000ms (1 hour). Delays up to 10 seconds are actually awaited in the Edge Function; longer delays are logged but not truly awaited.
- **Example config**:
  ```json
  { "duration_ms": 5000 }
  ```

### merge

Combines multiple execution paths into a single path. Takes the first non-null upstream value.

- **Required config**: none
- **Input ports**: `a` (any), `b` (any)
- **Output ports**: `out` (any)
- **Example config**: `{}`

### terminate

Immediately stops all rule execution. Unlike `stopFlow`, this is categorized as a flow control node rather than an action.

- **Required config**: none
- **Input ports**: `in` (any)
- **Output ports**: none
- **Example config**: `{}`
