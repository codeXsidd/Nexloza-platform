# Dashboard Builder Technical Guide

## Architecture

The dashboard builder follows Clean Architecture with these layers:

```
presentation/
  screens/
    dashboards_screen.dart      — List with search, filter, archive, import
    create_dashboard_screen.dart — Form with template selector
    dashboard_editor_screen.dart — Grid view + edit mode + config sheets
  widgets/
    widget_catalog_sheet.dart    — Bottom sheet for browsing/adding widgets
    data_source_selector.dart    — Cascading device/sensor dropdowns
    renderers/                   — 42 widget renderer functions
  providers/
    dashboard_provider.dart      — Riverpod state management

domain/
  entities/
    dashboard_entity.dart        — Dashboard model + 10 templates
    dashboard_widget_entity.dart — Widget model with config accessors
    data_source.dart             — Universal data binding model
    widget_type.dart             — NexWidgetType enum (42 types)
  widget_registry.dart           — Plugin registry + WidgetDataState

data/
  dashboard_repository.dart      — Supabase CRUD + import/export
  telemetry_data_service.dart    — Shared subscription manager
```

## Dashboard Editor Screen

The editor has three modes:

### View Mode (default)
- `GridView.builder` with responsive column count:
  - Width >= 900: 4 columns
  - Width >= 600: 3 columns
  - Width < 600: 2 columns
- Widgets rendered via `WidgetRegistry.build(context, widget, dataState)`
- Long-press to configure a widget
- Pull-to-refresh reloads widgets

### Edit Mode
- `ReorderableListView.builder` for drag-to-reorder
- Each item shows: icon, title, type, configure button, delete button, drag handle
- Reorder calls `DashboardRepository.reorderWidgets()` to persist order
- FAB appears to open widget catalog

### Full Screen Mode
- Hides the `AppBar`
- Floating exit button in top-right corner

## Widget Catalog Sheet

`WidgetCatalogSheet` is a `DraggableScrollableSheet` that displays all 42 widget types:

- Category filter chips (All, Control, Sensor, Chart, Status, Industrial, Info)
- Text search by widget name or typeId
- Each item shows icon, name, category, and add button
- Tapping adds the widget via `DashboardRepository.addWidget()`

## Widget Configuration

The `_WidgetConfigSheet` bottom sheet provides:

- Title text field
- DataSourceSelector for binding to device telemetry
- Unit, Min, Max fields
- Save button persists to `dashboard_widgets.config` JSONB

Config schema:
```json
{
  "data_source": { "project_id": "...", "device_id": "...", "sensor_key": "..." },
  "display": { "unit": "°C", "color": "#FF5722", "decimals": 1 },
  "range": { "min": 0, "max": 100 },
  "thresholds": [{ "value": 30, "color": "#FF0000" }],
  "chart": { "period": "24h", "aggregation": "avg" }
}
```

## Responsive Layout

The grid adapts to screen width:

| Screen Width | Columns | Target Device |
|---|---|---|
| < 600px | 2 | Phone |
| 600–899px | 3 | Tablet |
| >= 900px | 4 | Large tablet / desktop |

Widget aspect ratio is 1:1 (square cells). Chart and industrial widgets use `defaultWidth: 2` to span two columns when the grid supports it.

## App Startup

`registerAllWidgets()` is called in `main.dart` before `runApp()`. This registers all 42 widget renderers with the `WidgetRegistry` singleton.
