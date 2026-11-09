# Dashboard User Guide

## Overview

NEXLOZA dashboards let you monitor and control your IoT devices in real time. Each dashboard is a collection of widgets arranged in a responsive grid that adapts to your screen size.

## Creating a Dashboard

1. Navigate to **Dashboards** from the bottom navigation
2. Tap the **New Dashboard** button
3. Choose a template or start with **Custom Dashboard**
4. Select the project this dashboard belongs to
5. Enter a name and optional description
6. Tap **Create Dashboard**

### Templates

10 pre-configured templates are available:

| Template | Best For |
|----------|----------|
| Smart Home | Temperature, humidity, light controls |
| Smart Agriculture | Soil moisture, irrigation monitoring |
| Smart Irrigation | Valve controls, water flow |
| Weather Station | Environmental sensor data |
| Water Monitoring | Tank levels, flow rates |
| Energy Monitoring | Voltage, power consumption |
| Industrial IoT | Machine status, production |
| Machine Monitoring | Motor health, vibration |
| Smart Security | Motion sensors, alarms |
| Custom | Blank canvas |

## Adding Widgets

1. Open a dashboard and tap the **Edit** icon (pencil) in the app bar
2. Tap the **+** floating action button
3. Browse widgets by category or search by name
4. Tap a widget to add it to your dashboard

### Widget Categories

- **Control** — Interactive controls (switches, sliders, buttons)
- **Sensor** — Sensor value displays with units and thresholds
- **Chart** — Data visualization (line, bar, gauge, progress)
- **Status** — Device and connection status indicators
- **Industrial** — SCADA-style machine/equipment widgets
- **Info** — Text, clock, event logs, device lists

## Configuring Widgets

Long-press any widget in view mode (or tap the gear icon in edit mode) to configure:

1. **Title** — Display name for the widget
2. **Data Source** — Bind to a device sensor or actuator:
   - Select a **Project**
   - Select a **Device** (online status shown)
   - Select a **Sensor** or **Actuator**
3. **Unit** — Display unit (e.g., "°C", "%", "V")
4. **Min / Max** — Value range for gauges and progress bars

## Reordering Widgets

In edit mode, drag widgets using the handle icon on the right side to reorder them. The order is saved automatically.

## View Modes

- **Normal** — App bar with navigation, responsive grid
- **Full Screen** — Hides the app bar for maximum dashboard space
- **Edit Mode** — List view with reorder handles, configure/delete buttons

## Import / Export

### Export
1. Open a dashboard
2. Tap the menu (three dots) → **Export JSON**
3. Copy the JSON from the dialog

### Import
1. On the dashboards list, tap the menu → **Import JSON**
2. Paste the exported JSON
3. Tap **Import**

The format uses version 1 of `nexloza_dashboard` and includes all widget configurations.

## Dashboard Management

- **Search** — Filter dashboards by name or description
- **Archive** — Toggle the archive button to show/hide archived dashboards
- **Duplicate** — Create a copy of a dashboard with all its widgets
- **Rename** — Change the dashboard name from the editor menu
- **Delete** — Remove a dashboard and all its widgets
