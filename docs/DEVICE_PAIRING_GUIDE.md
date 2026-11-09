# Device Pairing Guide

## Overview

The Device Pairing Wizard is a guided 7-step flow designed to make onboarding new IoT devices beginner-friendly. It handles project selection, hardware setup instructions, device provisioning, credential generation, and connection verification.

## Accessing the Wizard

- From the **Devices** screen: tap the **+** FAB, or
- From a **Project Detail** screen: tap **Add Device**
- Route: `/devices/pair`

## Wizard Steps

### Step 1: Select Project

Choose which project this device belongs to. If you have only one project, it's auto-selected. The dropdown lists all active projects.

### Step 2: Select Hardware Platform

Pick your hardware board from the supported platforms:
- **ESP32** — Espressif dual-core, Wi-Fi + BLE
- **ESP8266** — Espressif single-core, Wi-Fi
- **Raspberry Pi** — Linux-based SBC
- **Arduino** — Microcontroller with Ethernet/WiFi shield
- **Generic MQTT** — Any device that speaks MQTT

Each option shows a brief description to help beginners choose.

### Step 3: Setup Instructions

Platform-specific instructions displayed in a card:
- Required hardware and connections
- Software prerequisites (Arduino IDE, PlatformIO, etc.)
- Library dependencies
- Network requirements

### Step 4: Device Details

Fill in the form:
- **Device Name** (required) — a friendly name like "Living Room Sensor"
- **Device Type** — sensor_node, actuator_node, gateway, or hybrid

### Step 5: Provisioning

The wizard:
1. Creates the device record in Supabase
2. Generates authentication credentials (device key + secret)
3. Displays a firmware configuration snippet you can copy-paste

**Important**: The device secret is shown only once. Copy it before proceeding.

Example snippet:
```cpp
#define DEVICE_ID     "abc-123-..."
#define DEVICE_KEY    "dev_abc123..."
#define DEVICE_SECRET "sec_xyz789..."
#define MQTT_HOST     "your-broker-host"
#define MQTT_PORT     1883
```

### Step 6: Verify Connection

After flashing firmware to your device:
1. Power on the device
2. The wizard polls the device's `is_online` status every 5 seconds
3. Timeout: 120 seconds
4. A progress indicator shows the connection check status

If verification times out, you can skip and verify later from the device detail screen.

### Step 7: Complete

Success screen with links to:
- **Configure Sensors** — add sensor definitions
- **Configure Actuators** — add actuator definitions
- **View Device** — go to the device detail screen

## Security Notes

- Device credentials are generated server-side via the `device-auth` Edge Function
- Authentication uses SHA-256 hash with constant-time comparison
- Credentials are never stored in the Flutter app beyond the provisioning display
- The device secret is shown once and cannot be retrieved again
- MQTT connections require valid device credentials

## Troubleshooting

See [DEVICE_TROUBLESHOOTING.md](DEVICE_TROUBLESHOOTING.md) for common issues.
