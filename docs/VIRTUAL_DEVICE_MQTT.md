# Virtual Device MQTT Integration

## Overview

Virtual devices use the same MQTT topic contract and pipeline as physical devices. No separate MQTT topics, brokers, or ingestion paths are created for virtual devices. The `TelemetryPublisher` bridges the in-memory `SimulatorEngine` to MQTT and Supabase using the existing canonical format.

## Topic Contract

Virtual devices follow the same NEXLOZA v1 topic format:

```
nexloza/v1/{organization_id}/{project_id}/{device_id}/{channel}
```

### Channels Used by Virtual Devices

| Channel | Direction | Purpose |
|---------|-----------|---------|
| telemetry | publish | Simulated sensor readings |
| command | subscribe | Actuator commands from the app |
| command-ack | publish | Command acknowledgment |
| state | publish | Device state updates |
| status | publish | Online/offline status |

## Telemetry Publishing

`TelemetryPublisher` listens to the `SimulatorEngine.stateStream` and, for each running device:

1. Filters enabled sensors that have no blocking fault (sensorFailure, deviceOffline).
2. Builds a readings array with `{key, value, timestamp}` per sensor.
3. Publishes to MQTT topic `nexloza/v1/{org}/{proj}/{device}/telemetry` as JSON:

```json
{
  "device_id": "uuid",
  "timestamp": "2026-11-01T12:00:00.000Z",
  "readings": [
    { "key": "temperature", "value": 22.3, "timestamp": "2026-11-01T12:00:00.000Z" },
    { "key": "humidity", "value": 55.1, "timestamp": "2026-11-01T12:00:00.000Z" }
  ]
}
```

4. Inserts into the `telemetry` table (same schema as `telemetry-ingest` Edge Function).
5. Updates `devices.last_seen_at` and `devices.is_online`.

## Command Handling

Actuator commands for virtual devices use the standard `CommandRepository.sendCommand()`:

1. The app sends a command via the `device-command` Edge Function.
2. The Edge Function inserts into `device_commands` and publishes to `nexloza/v1/{org}/{proj}/{device}/command`.
3. `SimulatorEngine.handleActuatorCommand()` processes the command by updating internal actuator state.
4. Actuator state changes influence subsequent sensor value computations (e.g., fan_speed affects temperature, water_pump affects soil_moisture).

## Connection Management

- `TelemetryPublisher` checks `MqttService.status == MqttConnectionStatus.connected` before publishing.
- If MQTT is disconnected, telemetry is still written to Supabase (database is the primary store; MQTT is for real-time push).
- The publisher does not create its own MQTT connection — it uses the shared `MqttService` singleton.

## Rate Limiting

- The `SimulatorEngine` enforces a minimum interval of 1000ms between ticks.
- The default interval is 5000ms (5 seconds).
- At maximum speed (10x), the effective interval is `5000 / 10 = 500ms`, but clamped to 1000ms minimum.
- This prevents flooding NanoMQ or Supabase with unbounded high-frequency messages.

## Fault Effects on MQTT

| Fault | MQTT Effect |
|-------|-------------|
| deviceOffline | No readings published; `is_online` remains stale |
| sensorFailure | The faulted sensor is excluded from readings |
| outOfRange | The sensor publishes values outside normal bounds |
| networkInterrupt | Simulates connectivity loss (no MQTT publish) |
| commandTimeout | Commands received but no ack published |

## NanoMQ Compatibility

Virtual device telemetry uses QoS 1 (`MqttQos.atLeastOnce`) for publishing, matching the same QoS level used by physical device firmware. The NanoMQ broker (emqx/nanomq:0.22.6-slim) handles virtual device messages identically to physical device messages.

## Security

- Virtual devices do not expose privileged MQTT credentials in Flutter.
- The `TelemetryPublisher` uses the app's existing MQTT connection, which authenticates through the standard device credential flow.
- No service-role or admin credentials are used for virtual device MQTT operations.
- Virtual device telemetry is subject to the same RLS policies as physical device telemetry.
