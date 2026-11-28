# Virtual Device MQTT Integration

## Overview

Virtual devices use the same MQTT topic contract and pipeline as physical devices. The simulator uses either direct Supabase storage or the MQTT telemetry path for each run. The disposable bridge forwards the exact fixture topic to the existing `telemetry-ingest` Edge Function.

## Topic Contract

Virtual devices follow the same NEXLOZA v1 topic format:

```
nexloza/v1/{organization_id}/{project_id}/{device_id}/{channel}
```

### Topic contract channels

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
  "message_id": "0ce985bc-1fa4-4d49-bd8f-dd3270e70c5d",
  "readings": [
    { "key": "temperature", "value": 22.3, "timestamp": "2026-11-01T12:00:00.000Z" },
    { "key": "humidity", "value": 55.1, "timestamp": "2026-11-01T12:00:00.000Z" }
  ]
}
```

In MQTT mode the worker passes the batch to the Edge Function. In direct mode the signed-in user writes virtual-device telemetry under RLS. Both paths use the same schema and deduplicate by device ID, message ID, and sensor key.

## Command Handling

The simulator engine can update actuator state through `handleActuatorCommand()`. The disposable telemetry bridge does not subscribe to or deliver commands. Relay, LED, and fan MQTT round trips still require scoped command routing and verification.

## Connection Management

- **Start with MQTT** creates a per-device native MQTT connection with a device API key and API secret. The application uses TLS by default.
- MQTT mode reports connection state, skipped readings, and submissions. It does not switch to direct storage on disconnect.
- **Start** uses direct storage under the signed-in user's virtual-device write policy.
- The UI displays the latest stored reading separately from MQTT submission status. Match its message ID to the bridge receipt.

## Rate Limiting

The simulator defaults to one tick every five seconds. Use the default speed for smoke tests. The Edge Function applies a per-device ingestion limit, so high simulation speeds or large profiles can hit that limit.

## Fault Effects on MQTT

| Fault | MQTT Effect |
|-------|-------------|
| deviceOffline | No readings published; `is_online` remains stale |
| sensorFailure | The faulted sensor is excluded from readings |
| outOfRange | The sensor publishes values outside normal bounds |
| networkInterrupt | Simulates connectivity loss (no MQTT publish) |
| commandTimeout | Requires a command transport to validate |

## NanoMQ Compatibility

Virtual device telemetry uses QoS 1 (`MqttQos.atLeastOnce`) for publishing, matching the same QoS level used by physical device firmware. The NanoMQ broker (emqx/nanomq:0.22.6-slim) handles virtual device messages identically to physical device messages.

## Security

- Virtual devices do not expose privileged MQTT credentials in Flutter.
- The disposable broker uses the fixture device credential and exact per-device ACL. It does not issue production credentials.
- No service-role or admin credentials are used for virtual device MQTT operations.
- Project members can read telemetry. Only project developers can directly insert virtual-device telemetry. Physical-device ingestion uses the Edge Function.

See [local setup](LOCAL_DEVELOPMENT_SETUP.md) and [runtime evidence](test-results/VIRTUAL_IOT_E2E_TEST.md).
