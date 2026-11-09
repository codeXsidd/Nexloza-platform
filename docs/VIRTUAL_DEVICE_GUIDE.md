# Virtual Device Guide

## Overview

Virtual devices are software-simulated IoT devices that produce realistic telemetry data without requiring physical hardware. They use the same NEXLOZA data pipeline as real devices — MQTT topics, telemetry ingestion, command handling, and dashboard visualization — so you can develop, test, and demonstrate IoT workflows entirely in software.

## Creating a Virtual Device

1. Navigate to a project and open **Virtual Devices**.
2. Tap the **+** button to open the creation form.
3. Enter a **name** and optional **description**.
4. Select a **simulation profile** from the horizontal card selector:

| Profile | Sensors | Actuators | Use Case |
|---------|---------|-----------|----------|
| Smart Home | 4 | 2 | Room environment monitoring and control |
| Agriculture | 4 | 1 | Crop monitoring with irrigation |
| Weather Station | 5 | 0 | Outdoor environmental sensing |
| Energy Monitoring | 5 | 0 | Power grid monitoring |
| Industrial Equipment | 4 | 2 | Motor and machine monitoring |
| Water Management | 4 | 2 | Tank and pipe monitoring |

5. Tap **Create**. The device, its sensors, actuators, and digital twin state are provisioned automatically.

The new device appears in both the Virtual Devices list and the standard Devices list, marked with a **VIRTUAL** badge.

## Running the Simulator

Open a virtual device and navigate to **Simulator Control**.

### Controls

- **Start** — Begins generating telemetry values based on the profile's simulation models. Values are published through the normal telemetry pipeline.
- **Pause** — Suspends value generation. Current state is preserved.
- **Resume** — Continues from where it paused.
- **Stop** — Halts simulation and cleans up timers.
- **Reset** — Returns all sensor values to their initial profile defaults.

### Speed and Interval

- **Speed**: 0.5x to 10x multiplier on the base update interval.
- **Interval**: 1–60 seconds between telemetry ticks (default 5 seconds).

### Per-Sensor Controls

Each sensor can be individually enabled or disabled during simulation. Disabled sensors stop producing telemetry but retain their last value.

## Viewing Simulated Telemetry

Simulated telemetry flows through the same pipeline as physical device data:

1. `SimulatorEngine` generates values in memory.
2. `TelemetryPublisher` writes readings to the `telemetry` table and publishes to MQTT.
3. `TelemetryDataService` (Phase 6) picks up the readings via Supabase Realtime.
4. Dashboard widgets display the values.

Open the device detail screen to see latest telemetry in the **Overview** tab and per-sensor readings in the **Sensors** tab.

## Dashboard Integration

Virtual devices are fully compatible with Phase 6 dashboards.

1. Open a dashboard and add or configure a widget.
2. In the **DataSourceSelector**, select a project and then a device.
3. Virtual devices appear with a **SIM** badge next to their name.
4. Select a sensor or actuator key to bind the widget.
5. The widget displays simulated values through the same rendering path as physical devices.

No separate dashboard editor or widget system is needed.

## Fault Scenario Testing

The simulator supports controlled fault injection for testing error handling:

| Fault | Effect |
|-------|--------|
| Device Offline | All sensors stop reporting |
| Sensor Failure | Selected sensor stops sending data |
| Out of Range | Selected sensor produces values outside valid bounds |
| Network Interrupt | Simulates connectivity loss |
| Command Timeout | Commands are received but never acknowledged |

To enable a fault:

1. Open the **Fault Injection** section in the simulator control.
2. Select a fault scenario.
3. Choose which sensor to apply it to (where applicable).
4. Toggle **Enable**.

Faults are scoped to the selected virtual device and sensor. They do not affect other devices.

## Digital Twin

Each virtual device has a digital twin that tracks:

- **Reported state** — What the simulator currently reports.
- **Desired state** — What the user wants the device to become.
- **Sync status** — Whether reported matches desired.

Open the **Digital Twin** screen from the device detail to see a side-by-side comparison with match/mismatch indicators.

## Limitations

- Virtual devices do not represent real hardware. They must never be presented as physically connected ESP32 or ESP8266 devices.
- Simulation models are approximations. Real sensor behavior depends on environmental conditions that are not modeled.
- Telemetry values are generated in the Flutter app, not by a real firmware running on a microcontroller.
- MQTT publishing depends on the app's MQTT connection being active.
- Phase 4 firmware has NOT been compiled with PlatformIO or physically tested on hardware.
- Android Emulator validation has not been performed for the complete virtual device flow.
