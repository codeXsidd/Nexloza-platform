# Actuator Configuration Guide

## Overview

Actuator definitions describe controllable outputs on a device — relays, motors, LEDs, valves, etc. Each actuator has a **command key** (used in MQTT command payloads) and a **control type** that determines the UI control presented to the user.

## Supported Actuator Types

| Type | Display Name | Typical Use |
|------|-------------|-------------|
| relay | Relay | On/off switching |
| light | Light | Lighting control |
| fan | Fan | Fan speed/on-off |
| pump | Pump | Water/fluid pumping |
| motor | Motor | Motor control |
| servo | Servo | Angular position |
| buzzer | Buzzer | Audio alerts |
| switch | Switch | General switching |
| smart_plug | Smart Plug | Mains outlet control |
| valve | Valve | Flow control |
| heater | Heater | Heating element |
| cooler | Cooler | Cooling element |
| lock | Lock | Door/gate lock |
| rgb_led | RGB LED | Color lighting |
| display | Display | Screen/message output |
| custom | Custom | User-defined |

## Control Types

The control type determines what UI control is rendered:

| Control Type | UI Element | Value Range |
|-------------|-----------|-------------|
| toggle | Switch | on/off (boolean) |
| slider | Slider | min to max (continuous) |
| numeric | Number input | min to max (discrete) |
| multi_level | Level selector | Predefined levels |
| color | Color picker | RGB values |
| custom | Command dialog | Free-form JSON |

## Adding an Actuator

1. Navigate to device detail > **Actuators** tab
2. Tap **Manage Actuators**
3. Tap the **+** FAB
4. Fill in:
   - **Name** — descriptive label (e.g., "Main Relay")
   - **Command Key** — the key in MQTT command payloads (e.g., `relay_1`)
   - **Actuator Type** — select from dropdown
   - **Control Type** — select the UI control style

## Editing an Actuator

Tap the edit icon to configure:

- **Name** — update the display name
- **Command Key** — read-only after creation (ensures payload consistency)
- **Telemetry Key** (optional) — maps to a telemetry field for state feedback
- **Min / Max** — value range for slider/numeric controls
- **Step** — increment step for slider/numeric controls

## Command Flow

```
User taps toggle        Flutter App              NanoMQ           Device
      |                      |                      |                |
      |-- tap ON ----------->|                      |                |
      |                      |-- MQTT publish ----->|                |
      |                      |   topic: .../command |-- forward ---->|
      |                      |   payload:           |                |
      |                      |   {"action":"set",   |                |
      |                      |    "actuator_id":"a1"|                |
      |                      |    "relay_1": true}  |                |
      |                      |                      |                |
      |                      |                      |<-- command-ack-|
      |                      |<-- MQTT subscribe ---|   {"command_id"|
      |                      |    .../command-ack   |    "status":   |
      |<-- UI update --------|                      |    "executed"} |
```

### Command States

| State | Icon | Meaning |
|-------|------|---------|
| pending | clock | Sent, waiting for device acknowledgment |
| acknowledged | check | Device received the command |
| executed | double-check | Device confirmed execution |
| failed | X | Device reported failure |

The command-ack channel provides real-time feedback. The UI updates the status icon and timestamp as acknowledgments arrive.

## Safety Limits

Actuators support `safety_limits` (stored as JSONB) for firmware-level enforcement:

```json
{
  "max_on_duration_seconds": 3600,
  "cooldown_seconds": 60,
  "requires_confirmation": true
}
```

These are advisory — the firmware must implement enforcement.

## Inline Controls

On the device detail **Actuators** tab:
- **Toggle actuators** show a Switch widget for instant on/off
- **Other control types** open a command dialog where you enter the value

All commands include the `actuator_id` in the payload so firmware can route to the correct output.

## Data Model

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| device_id | UUID | Parent device |
| name | text | Display name |
| actuator_type | enum | One of 16 types |
| control_type | enum | UI control style |
| command_key | text | MQTT payload key |
| telemetry_key | text | Optional state feedback key |
| min_value | float | Minimum value (default 0) |
| max_value | float | Maximum value (default 1) |
| step | float | Value increment (default 1) |
| current_state | jsonb | Last known state |
| safety_limits | jsonb | Safety configuration |
