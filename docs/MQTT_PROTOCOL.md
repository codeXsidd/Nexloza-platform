# MQTT Protocol Specification

## Canonical Topic Format

All MQTT communication in Nexloza uses the **v1 canonical topic format**:

```
nexloza/v1/{organization_id}/{project_id}/{device_id}/{channel}
```

### Segments

| Segment | Description |
|---------|-------------|
| `nexloza` | Platform namespace |
| `v1` | Protocol version — allows future breaking changes on `v2` |
| `organization_id` | UUID of the owning organization |
| `project_id` | UUID of the project |
| `device_id` | UUID of the device |
| `channel` | One of the defined channel types below |

### Channels

| Channel | QoS | Retained | Direction | Description |
|---------|-----|----------|-----------|-------------|
| `telemetry` | 0 | No | Device → Cloud | Sensor readings, periodic metrics |
| `command` | 1 | No | Cloud → Device | Commands sent to the device |
| `command-ack` | 1 | No | Device → Cloud | Command acknowledgements |
| `state` | 1 | Yes | Device → Cloud | Full device state snapshot |
| `status` | 1 | Yes | Device → Cloud | Online/offline status (also LWT) |
| `config` | 1 | Yes | Cloud → Device | Configuration pushed to device |

### Wildcard Subscriptions

| Pattern | Use Case |
|---------|----------|
| `nexloza/v1/{org}/{project}/{device}/#` | All channels for one device |
| `nexloza/v1/{org}/{project}/#` | All devices in a project |

## Payload Format

All payloads are **JSON**. Telemetry example:

```json
{
  "temperature": 23.5,
  "humidity": 61.2,
  "timestamp": "2026-11-09T10:30:00Z"
}
```

Command example:

```json
{
  "command_id": "uuid",
  "command_type": "set_relay",
  "payload": { "state": true }
}
```

Status (LWT and online):

```json
{ "status": "online" }
{ "status": "offline" }
```

## Authentication

Devices authenticate to the MQTT broker with their `device_id` as username and `api_key` as password. The device-auth Edge Function returns the credentials and pre-computed topics on successful authentication.

## Last Will and Testament (LWT)

Every device sets an LWT on the `status` channel:

- Topic: `nexloza/v1/{org}/{project}/{device}/status`
- Payload: `{"status":"offline"}`
- QoS: 1
- Retained: true

On connect, the device publishes `{"status":"online"}` to the same topic (retained).

## Implementation References

| Component | File |
|-----------|------|
| Flutter constants | `app/lib/core/constants/mqtt_constants.dart` |
| Flutter MQTT service | `app/lib/core/services/mqtt_service.dart` |
| Flutter device provider | `app/lib/features/devices/presentation/providers/device_mqtt_provider.dart` |
| Firmware SDK | `firmware/nexloza-sdk/src/NexlozaClient.cpp` |
| Edge Function (auth) | `backend/supabase/functions/device-auth/index.ts` |
| Edge Function (command) | `backend/supabase/functions/device-command/index.ts` |
| Code generator | `app/lib/features/device_studio/domain/code_generator.dart` |
