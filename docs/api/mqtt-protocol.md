# Nexloza MQTT Protocol

## Topic Structure

All topics follow the pattern: `nexloza/{project_id}/{device_id}/{channel}`

| Channel | Direction | QoS | Description |
|---------|-----------|-----|-------------|
| `telemetry/{sensor_key}` | Device → Cloud | 1 | Sensor readings |
| `commands` | Cloud → Device | 1 | Commands from app/automations |
| `state` | Device → Cloud | 1 | Device/actuator state reports |
| `heartbeat` | Device → Cloud | 0 | Periodic health check |
| `ota` | Cloud → Device | 1 | Firmware update notifications |

## Payload Formats

### Telemetry
```json
{
  "key": "temperature",
  "value": 23.5,
  "unit": "°C",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Command
```json
{
  "id": "cmd-uuid",
  "type": "set_state",
  "payload": { "relay_1": true },
  "expires_at": "2024-01-15T10:31:00Z"
}
```

### Command Acknowledgement
```json
{
  "command_id": "cmd-uuid",
  "success": true,
  "message": "Relay 1 turned ON"
}
```

### Heartbeat
```json
{
  "uptime_ms": 3600000,
  "free_heap": 120000,
  "rssi": -45,
  "firmware": "1.0.0"
}
```

### State Report
```json
{
  "actuator_key": "relay_1",
  "state": { "on": true },
  "timestamp": "2024-01-15T10:30:00Z"
}
```
