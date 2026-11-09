# Widget Development Guide

## Overview

The NEXLOZA widget system uses a plugin architecture. Each widget type is a pure function that takes a `BuildContext`, `DashboardWidget`, and `WidgetDataState` and returns a `Widget`. New widget types can be added without modifying existing code.

## Creating a New Widget

### Step 1: Add to NexWidgetType enum

In `lib/features/dashboards/domain/entities/widget_type.dart`:

```dart
enum NexWidgetType {
  // ... existing types ...
  myNewWidget('my_new_widget', 'My New Widget', WidgetCategory.sensor, Icons.new_releases),
}
```

Parameters: `typeId` (snake_case DB identifier), `displayName`, `category`, `icon`.

### Step 2: Write the renderer function

Create or add to a renderer file in `presentation/widgets/renderers/`:

```dart
Widget buildMyNewWidget(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  if (data.isLoading) {
    return Card(
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: theme.textTheme.titleSmall),
          const Spacer(),
          Text(data.stringValue, style: theme.textTheme.headlineSmall),
          const Spacer(),
        ],
      ),
    ),
  );
}
```

### Step 3: Register the widget

In `presentation/widgets/renderers/widget_registrations.dart`:

```dart
WidgetRegistration(
  type: NexWidgetType.myNewWidget,
  builder: buildMyNewWidget,
),
```

### Step 4: Update DB migration (if needed)

If the widget type needs to persist to the database, the `widget_type` column is now `text` (not an enum), so new typeIds work automatically.

## WidgetDataState Contract

```dart
class WidgetDataState {
  final dynamic currentValue;  // Latest telemetry value
  final bool isLoading;        // Initial load state
  final String? error;         // Error message if failed
  final List<({DateTime time, double value})> history;  // Time series data
  final Map<String, dynamic> deviceInfo;  // Device metadata
  final bool isStale;          // Data hasn't updated recently
}
```

Convenience getters:
- `numericValue` — Converts to double (from num, String, or 0)
- `boolValue` — Converts to bool (from bool, num, String)
- `stringValue` — Converts to String (or '--' if null)
- `hasData` — `currentValue != null`
- `hasError` — `error != null`

## Widget Configuration

Access widget config through `DashboardWidget` accessors:

```dart
widget.dataSource     // DataSource from config['data_source']
widget.rangeMin       // double from config['range']['min'] (default: 0)
widget.rangeMax       // double from config['range']['max'] (default: 100)
widget.unit           // String from config['display']['unit']
widget.decimals       // int from config['display']['decimals'] (default: 1)
widget.thresholds     // List<Map> from config['thresholds']
widget.displayConfig  // Map from config['display']
widget.chartConfig    // Map from config['chart']
```

## Widget Categories

| Category | Count | Purpose |
|---|---|---|
| Control | 8 | Interactive device controls |
| Sensor | 10 | Sensor value displays |
| Chart | 8 | Data visualization |
| Status | 6 | Device/connection status |
| Industrial | 5 | SCADA-style displays |
| Info | 5 | Text, logs, lists |

## Best Practices

1. Always handle `data.isLoading` — show a loading indicator
2. Use `widget.title` for the display title, not a hardcoded string
3. Read config values through the entity's typed accessors
4. Keep renderers as pure functions — no side effects
5. Use `Theme.of(context)` for colors, not hardcoded values
6. Respect error isolation — never throw from a renderer
