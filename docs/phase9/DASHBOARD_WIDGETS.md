# Phase 9 — Dashboard Widgets

## New Widget Types

Phase 9 adds 5 alarm-related widgets to the dashboard builder (Phase 6), bringing the total to 47 widget types.

All widgets are in the `status` category and are registered in `widget_registrations.dart`.

### alarmCount

Displays the total count of active alarms.

- Default size: 2×2
- Shows a large number with "Active Alarms" label
- Color: warning (amber)

### criticalAlarmCount

Displays the count of critical-severity active alarms.

- Default size: 2×2
- Shows a large number with "Critical Alarms" label
- Color: error (red)
- Highlights when count > 0

### unacknowledgedAlarmCount

Displays the count of unacknowledged alarms (active but not yet acknowledged).

- Default size: 2×2
- Shows a large number with "Unacknowledged" label
- Color: warning (amber)

### alarmSeverityDistribution

Shows a breakdown of active alarms by severity level.

- Default size: 4×3
- Displays horizontal bars for each severity level
- Uses severity-specific colors (red, deep orange, orange, amber, blue)

### recentAlarmActivity

Lists the most recent alarm activity entries.

- Default size: 4×4
- Shows a scrollable list of recent activities
- Each entry shows type, alarm title, timestamp, and user

## Widget Renderers

All 5 renderers are defined in `alarm_widgets.dart`:
- `renderAlarmCountWidget()`
- `renderCriticalAlarmCountWidget()`
- `renderUnacknowledgedAlarmCountWidget()`
- `renderAlarmSeverityDistributionWidget()`
- `renderRecentAlarmActivityWidget()`

Each renderer follows the existing widget renderer pattern:
- Accepts `WidgetRef ref` and `Map<String, dynamic> config`
- Uses Riverpod providers from `alarm_providers.dart`
- Handles loading and error states
- Renders within the dashboard grid cell constraints

## Registration

Widgets are registered in the `widgetRenderers` map in `widget_registrations.dart`:

```dart
NexWidgetType.alarmCount: renderAlarmCountWidget,
NexWidgetType.criticalAlarmCount: renderCriticalAlarmCountWidget,
NexWidgetType.unacknowledgedAlarmCount: renderUnacknowledgedAlarmCountWidget,
NexWidgetType.alarmSeverityDistribution: renderAlarmSeverityDistributionWidget,
NexWidgetType.recentAlarmActivity: renderRecentAlarmActivityWidget,
```

## Integration with Dashboard Builder

These widgets are available in the dashboard widget picker alongside all Phase 6 widgets. Users can drag them onto any dashboard and resize them within the grid. One broken widget does not crash the entire dashboard — each widget renderer catches its own errors.
