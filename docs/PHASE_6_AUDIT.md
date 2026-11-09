# Phase 6 Audit — Dashboard Builder, Widget Engine and Real-Time Telemetry

**Date**: 2026-11-09
**Commit**: 9d33701 (Phase 5)
**Branch**: main
**Tests**: 259/259 passing, 0 analyze issues

## Existing Dashboard Infrastructure

### Dashboard Entity — IMPLEMENTED
- `Dashboard` class: id, projectId, name, description, isDefault, dates
- Missing: icon, background, theme, isArchived, layout config, sharing, variables

### DashboardWidget Entity — PARTIALLY IMPLEMENTED
- `DashboardWidget` class: id, dashboardId, widgetType, title, gridX/Y/W/H, config, sortOrder
- `DashboardWidgetType` enum: 7 types (gauge, lineChart, valueDisplay, toggle, statusIndicator, barChart, map)
- DB `widget_type` enum has 25 types — Flutter only implements 7
- Has copyWith — good for editor operations
- Missing: data source binding, update interval, responsive config

### Dashboard Repository — IMPLEMENTED
- CRUD for dashboards and widgets
- Uses Result pattern with proper error handling
- Missing: update dashboard, duplicate, archive/restore, import/export, sharing

### Dashboard Provider — IMPLEMENTED
- `DashboardsNotifier` with create/delete
- `dashboardWidgetsProvider` for widget list
- Missing: update dashboard, widget reordering, data source providers

### Dashboard Screens — PARTIALLY IMPLEMENTED
- `DashboardsScreen`: list with delete, FAB for create — no search/filter
- `CreateDashboardScreen`: project selection, name, description — no templates
- `DashboardEditorScreen`: fixed 2-column GridView, edit mode toggle, add widget sheet
  - No drag-and-drop, no resize, no widget configuration, no data binding
  - Add widget only takes title + type — no data source selection

### Widget Cards — PARTIALLY IMPLEMENTED
- `GaugeWidgetCard`: custom arc painter, reads value/min/max/unit from config — static only
- `ValueDisplayWidgetCard`: displays value/unit/label from config — static only
- `ToggleWidgetCard`: local switch state, no MQTT command integration
- `StatusIndicatorWidgetCard`: online/offline indicator from config — static only
- `ChartWidgetCard`: line/bar custom painters from config data array — static only
- None connect to live telemetry or actual device data

### Telemetry Infrastructure — VERIFIED
- `TelemetryReading` entity: id, deviceId, sensorKey, valueNumeric/Text/Json, timestamps
- `TelemetryRepository`: getLatestReadings, getSensorReadings (with date filter), getLatestPerSensor, watchTelemetry (Supabase stream)
- Providers: latestTelemetryProvider, telemetryHistoryProvider, telemetryStreamProvider
- Ready to wire into dashboard widgets

### MQTT Service — VERIFIED
- `MqttService` singleton with connect/subscribe/publish/disconnect
- Auto-reconnect, status/message streams
- `mqttServiceProvider`, `mqttStatusProvider`
- `DeviceMqttController` for device-specific subscriptions
- AppScaffold has MQTT status indicators

### Database Schema — VERIFIED
- `dashboards` table: id, project_id, name, description, layout (jsonb), is_default, sort_order, RLS
- `dashboard_widgets` table: id, dashboard_id, widget_type (enum with 25 types), title, config (jsonb with documented data_source schema), sort_order, is_visible, RLS
- `telemetry` table: device_id, sensor_key, value_numeric/text/json, recorded_at — indexed
- Proper RLS policies on all tables

### Sensor/Actuator Models — VERIFIED
- `SensorDefinition`: 24 types, telemetryKey, thresholds, sampling config
- `ActuatorDefinition`: 16 types, 6 control types, commandKey, min/max/step

## Classification Summary

| Feature | Status |
|---------|--------|
| Dashboard CRUD | IMPLEMENTED |
| Dashboard entity | PARTIALLY IMPLEMENTED |
| Widget entity with grid position | IMPLEMENTED |
| Widget type enum (DB: 25 types) | IMPLEMENTED |
| Widget type enum (Flutter: 7 types) | PARTIALLY IMPLEMENTED |
| Dashboard repository | IMPLEMENTED |
| Widget rendering (5 cards) | PARTIALLY IMPLEMENTED |
| Data binding to telemetry | MISSING |
| Drag-and-drop editor | MISSING |
| Widget resize | MISSING |
| Widget configuration UI | MISSING |
| Dashboard templates | MISSING |
| Dashboard import/export | MISSING |
| Dashboard sharing | MISSING |
| Dashboard filters/variables | MISSING |
| Historical charts with date range | MISSING |
| Telemetry aggregation | MISSING |
| Widget registry/plugin architecture | MISSING |
| SCADA widgets | MISSING |
| Alarm/event widgets | MISSING |
| Full-screen mode | MISSING |
| Dashboard search/filter | MISSING |
| MQTT telemetry → widget binding | MISSING |
| Telemetry infrastructure | VERIFIED |
| MQTT service | VERIFIED |
| Supabase RLS | VERIFIED |
| Sensor/actuator models | VERIFIED |

## Issues Found

1. Flutter widget types (7) don't match DB enum (25) — need to expand
2. Widget config uses `widget_type` as Dart enum name but DB uses different values — need mapping
3. Existing widgets read static config values, no live data binding
4. ToggleWidgetCard has local state only, doesn't send MQTT commands
5. ChartWidgetCard expects data array in config, not from telemetry queries
6. DashboardEditorScreen uses fixed GridView, no drag/drop/resize
7. Dashboard entity missing fields present in DB (layout, sort_order)
8. No dashboard update method in repository
9. No widget reordering capability
10. No responsive grid — fixed 2 columns regardless of screen size
