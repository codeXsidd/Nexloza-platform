# Telemetry Visualization Guide

## Overview

NEXLOZA provides 8 chart widgets and 10 sensor card widgets for visualizing IoT telemetry data. All visualizations use Flutter's `CustomPaint` for lightweight, dependency-free rendering.

## Chart Widgets

### Line Chart (`line_chart`)
Plots time-series data as a connected line with a translucent fill beneath. Uses `_SimpleChartPainter` with stroke rendering and area fill.

### Area Chart (`area_chart`)
Similar to line chart but with a more prominent filled area under the curve. Uses the tertiary color scheme for differentiation.

### Bar Chart (`bar_chart`)
Renders data points as vertical bars with rounded tops. Bar width is 70% of available space per data point.

### Gauge (`gauge`)
Arc-style gauge using `_GaugePainter`. Displays value as text in the center with a 252° sweep arc. Configurable via `rangeMin`/`rangeMax`.

### Radial Gauge (`radial_gauge`)
Circular progress indicator style. Shows percentage in the center and value with unit below.

### Progress Bar (`progress_bar`)
Horizontal bar with min/max labels. Shows current value and percentage. Uses `ClipRRect` for rounded corners.

### Realtime Chart (`realtime_chart`)
Line chart with a live indicator dot (green=connected, red=stale). Same rendering as line chart but with real-time data emphasis.

### Min/Max/Avg (`min_max_avg`)
Three-column statistics display. Calculates min, max, and average from history data. Color-coded: blue (min), primary (avg), red (max).

## Sensor Card Widgets

Each sensor card displays a single value with context-appropriate formatting:

| Widget | Icon | Special Features |
|---|---|---|
| Temperature | Thermostat | Threshold-based color |
| Humidity | Water Drop | Standard value display |
| Pressure | Speed | Standard value display |
| Soil Moisture | Grass | Linear progress bar (green/orange/red) |
| Water Level | Waves | Standard value display |
| Light | Sun | Standard value display |
| Motion | Running | Boolean indicator (detected/clear) |
| Voltage | Bolt | Standard value display |
| Power | Electrical | Standard value display |
| Battery | Battery icon | Dynamic icon based on level, red below 20% |

## Threshold Colors

Sensor widgets support configurable thresholds in the widget config:

```json
{
  "thresholds": [
    { "value": 20, "color": "#4CAF50" },
    { "value": 30, "color": "#FF9800" },
    { "value": 40, "color": "#F44336" }
  ]
}
```

The `_thresholdColor()` function evaluates thresholds in reverse order (highest first) and returns the color of the first threshold the current value exceeds.

## Historical Data

Use `TelemetryDataService.getHistory()` to query time-range data:

```dart
final history = await telemetryService.getHistory(
  deviceId: 'device-uuid',
  sensorKey: 'temperature',
  from: DateTime.now().subtract(Duration(hours: 24)),
  to: DateTime.now(),
  limit: 500,
);
```

Data is returned as `List<TelemetryReading>` ordered by `recorded_at`. Chart widgets consume this via `WidgetDataState.history`.

## Data Flow

```
Supabase Realtime → TelemetryDataService (shared subscription)
                         ↓
                   _latestValues cache
                         ↓
              DashboardGrid._buildDataState()
                         ↓
                    WidgetDataState
                         ↓
              WidgetRegistry.build() → Renderer Function → Widget
```

## Custom Chart Painters

All charts use `CustomPainter` subclasses:

- `_SimpleChartPainter` — Line, area, and bar charts (configurable via `_ChartType` enum)
- `_GaugePainter` — Arc gauge with track and value arcs
- `_TankPainter` — SCADA-style tank level visualization (industrial widgets)

These painters implement `shouldRepaint` for efficient redraws only when data changes.

## Performance

- Widgets share telemetry subscriptions via reference counting
- `CustomPaint` renders directly to the canvas without widget tree overhead
- Grid uses `GridView.builder` for lazy rendering of off-screen widgets
- Error isolation: each widget is independently rendered — one failure doesn't cascade
