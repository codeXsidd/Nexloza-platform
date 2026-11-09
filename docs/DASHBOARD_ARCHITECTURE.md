# Dashboard Architecture

## Overview

The NexIoza dashboard system follows a layered architecture:

```
┌─────────────────────────────────────────────┐
│           Dashboard Screens (UI)            │
│   DashboardsScreen, DashboardEditorScreen   │
├─────────────────────────────────────────────┤
│            Widget Renderer                  │
│   Reads WidgetRegistry, renders by type     │
├─────────────────────────────────────────────┤
│         Widget Registry (catalog)           │
│   WidgetDefinition manifest per type        │
├──────────────────┬──────────────────────────┤
│  Data Binding    │   Widget Config          │
│  DataSource      │   Appearance, thresholds │
│  TelemetryData   │   Units, formatting      │
├──────────────────┴──────────────────────────┤
│         Data Layer (providers)              │
│   TelemetryDataService (shared subs)        │
│   DashboardRepository, DashboardProvider    │
├─────────────────────────────────────────────┤
│         Backend (Supabase + MQTT)           │
│   dashboards, dashboard_widgets tables      │
│   telemetry table, MqttService              │
└─────────────────────────────────────────────┘
```

## Widget Registry

Each widget type is registered with a `WidgetDefinition`:

```dart
class WidgetDefinition {
  final String type;          // unique identifier
  final String displayName;
  final String category;      // control, sensor, chart, status, industrial, info
  final IconData icon;
  final Set<DataType> supportedDataTypes;
  final WidgetBuilder builder; // (DashboardWidget, DataSource?) → Widget
  final int defaultWidth;
  final int defaultHeight;
}
```

The registry allows future widgets to be added without modifying the dashboard engine.

## Data Binding

Widgets connect to data through a `DataSource`:

```dart
class DataSource {
  final String? deviceId;
  final String? sensorKey;
  final String? actuatorKey;
  final String? telemetryKey;
}
```

The `TelemetryDataService` manages shared subscriptions:
- Multiple widgets watching the same device share one subscription
- Supabase Realtime stream for database-backed telemetry
- Reference counting for cleanup

## Dashboard Layout

Dashboards use a responsive grid:
- Mobile (< 600px): 2 columns
- Tablet (600-900px): 3 columns
- Large (> 900px): 4 columns

Widgets have grid positions (x, y, w, h) stored in the database.
On mobile, the editor uses a reorderable list rather than free-form drag.

## Widget Config Schema

Each widget's `config` JSONB follows:

```json
{
  "data_source": {
    "device_id": "uuid",
    "sensor_key": "temperature",
    "actuator_key": null
  },
  "display": {
    "color": "#4CAF50",
    "icon": "thermostat",
    "unit": "°C",
    "decimals": 1
  },
  "thresholds": [
    {"value": 30, "color": "#FF9800", "label": "Warning"},
    {"value": 45, "color": "#F44336", "label": "Critical"}
  ],
  "chart": {
    "period": "24h",
    "aggregation": "avg",
    "show_grid": true
  },
  "range": {
    "min": 0,
    "max": 100
  }
}
```

## Security

- Dashboard access enforced via Supabase RLS (project membership)
- Widget data sources validated against user's project access
- No privileged MQTT credentials in Flutter
- Import validation prevents arbitrary code execution
- Actuator commands routed through device-command Edge Function
