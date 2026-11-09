# Sensor Configuration Guide

## Overview

Sensor definitions tell NexIoza what telemetry data a device produces. Each sensor maps a **telemetry key** (the JSON field name in MQTT payloads) to a typed sensor with units, thresholds, and sampling configuration.

## Supported Sensor Types

NexIoza supports 24 sensor types:

| Type | Display Name | Typical Unit |
|------|-------------|--------------|
| temperature | Temperature | celsius, fahrenheit |
| humidity | Humidity | percent |
| pressure | Pressure | hPa, PSI |
| soil_moisture | Soil Moisture | percent |
| light | Light | lux |
| uv | UV Index | index |
| gas | Gas | ppm |
| co2 | CO2 | ppm |
| dust | Dust/PM | ug/m3 |
| rain | Rain | mm |
| wind_speed | Wind Speed | m/s, km/h |
| wind_direction | Wind Direction | degrees |
| water_level | Water Level | cm |
| water_flow | Water Flow | L/min |
| ph | pH | pH |
| dissolved_oxygen | Dissolved Oxygen | mg/L |
| voltage | Voltage | V |
| current | Current | A |
| power | Power | W |
| energy | Energy | kWh |
| vibration | Vibration | mm/s |
| sound | Sound | dB |
| motion | Motion | boolean |
| custom | Custom | user-defined |

## Adding a Sensor

1. Navigate to a device's detail screen
2. Go to the **Sensors** tab
3. Tap **Manage Sensors**
4. Tap the **+** FAB (Add Sensor)
5. Fill in:
   - **Name** — descriptive label (e.g., "Room Temperature")
   - **Telemetry Key** — the JSON key your firmware sends (e.g., `temperature`)
   - **Sensor Type** — select from dropdown
   - **Unit** (optional) — measurement unit

## Editing a Sensor

Tap the edit icon on any sensor tile to configure:

### Basic Fields
- **Name** — update the display name
- **Unit** — change or set the unit

### Sampling Interval
- Enter the interval in **seconds** (displayed to user)
- Stored internally as milliseconds
- Controls how frequently the device should send readings

### Value Range
- **Min** / **Max** — expected value range
- Used for UI gauge/chart scaling and anomaly detection

### Warning Thresholds
- **Warn Low** / **Warn High** — values that trigger a warning alert
- Example: temperature warning at < 5C or > 40C

### Critical Thresholds
- **Crit Low** / **Crit High** — values that trigger a critical alert
- Example: temperature critical at < -10C or > 60C

## Telemetry Data Flow

```
Device                      NanoMQ Broker                 NexIoza App
  |                              |                             |
  |-- MQTT publish ------------->|                             |
  |   topic: .../telemetry       |                             |
  |   payload: {"temperature":   |-- forward ----------------->|
  |             23.5,            |                             |
  |             "humidity": 65}  |                  DeviceMqttController
  |                              |                  matches telemetry_key
  |                              |                  to SensorDefinition
```

## Firmware Payload Format

Your device should publish JSON to the `telemetry` channel:

```json
{
  "temperature": 23.5,
  "humidity": 65.2,
  "timestamp": 1700000000
}
```

Each top-level key should match a sensor's `telemetry_key`. The `timestamp` field is optional — the server records receipt time if omitted.

## Data Model

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| device_id | UUID | Parent device |
| name | text | Display name |
| sensor_type | enum | One of 24 types |
| telemetry_key | text | JSON key in payload |
| unit | text | Measurement unit |
| min_value | float | Expected minimum |
| max_value | float | Expected maximum |
| sampling_interval_ms | int | Sampling rate (ms) |
| warning_threshold_low | float | Warning low limit |
| warning_threshold_high | float | Warning high limit |
| critical_threshold_low | float | Critical low limit |
| critical_threshold_high | float | Critical high limit |
