# Device Management Guide

## Overview

Devices are the core of NexIoza. Each device represents a physical IoT board (ESP32, ESP8266, Raspberry Pi, Arduino, or generic MQTT client) connected to the platform via the NanoMQ MQTT broker.

## Devices Screen

### Search

The search bar at the top filters devices by name or device type in real-time.

### Filter Chips

Horizontal filter chips allow filtering by:
- **All** — show everything
- **Online** — only devices currently connected
- **ESP32** / **ESP8266** / **RPi** / **Arduino** — filter by hardware platform

Filters are mutually exclusive — selecting a platform clears the online filter and vice versa.

### Device Cards

Each card displays:
- Platform-specific icon (chip icon for ESP, board icon for RPi/Arduino)
- Online/offline status badge with color indicator
- Device name
- Hardware platform and firmware version
- Last seen time (using relative "timeago" format)

Tapping a card navigates to the device detail screen.

## Device Detail Screen

The detail screen uses a **tabbed layout** with four tabs:

### Overview Tab
- Device info card (name, type, platform, firmware, MAC address)
- **MQTT badge** showing real-time connection status (Connected/Connecting/Disconnected/Error)
- **Stale data warning** — shown when the device is offline, alerting that displayed data may be outdated
- Latest telemetry readings

### Sensors Tab
- Lists all sensor definitions attached to this device
- Shows latest reading for each sensor
- **Manage Sensors** button navigates to the full sensor management screen

### Actuators Tab
- Lists all actuator definitions
- Inline controls: toggle switch for on/off actuators, command dialog for others
- Commands include the `actuator_id` in the payload for proper firmware routing
- **Manage Actuators** button for full management

### Commands Tab
- Full command history with status icons (pending, acknowledged, executed, failed)
- Relative timestamps via timeago
- **Send Command** dialog for manual command dispatch

## Adding a Device

Two paths:
1. **Quick Add** (`/devices/add`) — simple form for name, type, platform, project
2. **Guided Pairing** (`/devices/pair`) — 7-step onboarding wizard (see DEVICE_PAIRING_GUIDE.md)

## Data Model

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| project_id | UUID | Parent project |
| name | text | Device name |
| device_type | text | sensor_node, actuator_node, gateway, etc. |
| hardware_platform | enum | esp32, esp8266, raspberry_pi, arduino, generic_mqtt, other |
| firmware_version | text | Current firmware version |
| mac_address | text | Hardware MAC address |
| is_online | boolean | Current connection status |
| is_active | boolean | Enabled/disabled flag |
| last_seen_at | timestamptz | Last MQTT heartbeat |

## MQTT Topics

Each device subscribes to and publishes on its canonical topic path:

```
nexloza/v1/{org_id}/{project_id}/{device_id}/telemetry   (QoS 0)
nexloza/v1/{org_id}/{project_id}/{device_id}/command      (QoS 1)
nexloza/v1/{org_id}/{project_id}/{device_id}/command-ack  (QoS 1)
nexloza/v1/{org_id}/{project_id}/{device_id}/state        (QoS 1, retained)
nexloza/v1/{org_id}/{project_id}/{device_id}/status       (QoS 1, retained)
nexloza/v1/{org_id}/{project_id}/{device_id}/config       (QoS 1, retained)
```
