# Phase 6 Implementation Plan

## Strategy

Build in layers: core engine first, then widgets, then features.

## Step 1: Widget Registry and Data Source Abstraction
- Create `WidgetDefinition` manifest (type, config schema, supported data types)
- Create `WidgetRegistry` with registration and lookup
- Create `DataSource` abstraction (device, sensor, actuator, telemetry key)
- Create `DataBinding` model linking widgets to data sources
- Create `TelemetryDataService` for shared subscriptions

## Step 2: Enhanced Dashboard Entity and Repository
- Expand `Dashboard` with icon, isArchived, layout config, theme, variables
- Add repository methods: update, duplicate, archive/restore
- Add dashboard search/filter to list screen
- Add dashboard templates

## Step 3: Visual Dashboard Editor
- Replace fixed GridView with reorderable grid
- Add widget add/remove/reorder via long-press drag on mobile
- Add widget configuration bottom sheet (data source, appearance)
- Add edit/view mode toggle
- Add full-screen mode

## Step 4: Widget Catalog — Core Set
Implement widgets across all categories using the registry:

### Control Widgets (8)
Switch, Button, Slider, Numeric Input, Dropdown, Fan Speed, Relay Control, Valve Control

### Sensor Widgets (10)
Temperature, Humidity, Pressure, Soil Moisture, Water Level, Light, Motion, Voltage, Power, Battery

### Chart Widgets (8)
Line Chart, Area Chart, Bar Chart, Gauge, Radial Gauge, Progress Bar, Real-time Chart, Min/Max/Avg

### Status Widgets (6)
Device Online/Offline, MQTT Status, Device Health, Alarm, Command Status, Last Seen

### Industrial Widgets (5)
Machine Status, Tank Level, Motor Status, Equipment Status, Alarm Panel

### Info Widgets (5)
Text, Markdown, Clock, Event Log, Device List

**Total: 42 widgets** in initial catalog

## Step 5: Data Binding Engine
- Widget configuration UI: project → device → sensor/actuator → telemetry key
- Cascading dropdowns
- Data type validation
- Unit configuration
- Threshold configuration
- Live preview during binding

## Step 6: Historical Telemetry
- Time range selector (5m, 15m, 1h, 6h, 24h, 7d, 30d, custom)
- Aggregation (raw, min, max, avg, sum, count)
- Multi-series support
- CSV/JSON export
- Query pagination

## Step 7: Dashboard Filters and Variables
- Dashboard-level device/date filter
- Filter propagation to all widgets
- Dashboard variables

## Step 8: Import/Export
- Versioned JSON format
- Export dashboard with widgets
- Import with validation
- Duplicate dashboard

## Step 9: Tests and Documentation
- Preserve 259 existing tests
- Add widget registry, data binding, entity, import/export tests
- Create 8 documentation files
- Completion report

## Step 10: Final Verification
- flutter format, analyze, test
- Commit and push
