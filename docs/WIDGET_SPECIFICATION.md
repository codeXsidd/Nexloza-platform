# Widget Specification

## Widget Categories and Types

### A. Control Widgets
| # | Type ID | Display Name | Data Type | Control |
|---|---------|-------------|-----------|---------|
| 1 | switch | Switch | boolean | Toggle on/off |
| 2 | button | Button | command | Send command |
| 3 | slider | Slider | numeric | Continuous range |
| 4 | numeric_input | Numeric Input | numeric | Direct value entry |
| 5 | dropdown | Dropdown | enum | Select from options |
| 6 | fan_speed | Fan Speed | numeric | Multi-level speed |
| 7 | relay_control | Relay Control | boolean | Relay on/off with state |
| 8 | valve_control | Valve Control | boolean | Valve open/close |

### B. Sensor Widgets
| # | Type ID | Display Name | Data Type | Visualization |
|---|---------|-------------|-----------|---------------|
| 9 | temperature_card | Temperature | numeric | Value + icon + unit |
| 10 | humidity_card | Humidity | numeric | Value + icon + unit |
| 11 | pressure_card | Pressure | numeric | Value + icon + unit |
| 12 | soil_moisture_card | Soil Moisture | numeric | Value + progress |
| 13 | water_level_card | Water Level | numeric | Fill indicator |
| 14 | light_card | Light Intensity | numeric | Value + icon |
| 15 | motion_card | Motion | boolean | Detected/clear |
| 16 | voltage_card | Voltage | numeric | Value + unit |
| 17 | power_card | Power | numeric | Value + unit |
| 18 | battery_card | Battery | numeric | Percentage fill |

### C. Data Visualization Widgets
| # | Type ID | Display Name | Data Type | Chart |
|---|---------|-------------|-----------|-------|
| 19 | line_chart | Line Chart | numeric[] | Time series |
| 20 | area_chart | Area Chart | numeric[] | Filled time series |
| 21 | bar_chart | Bar Chart | numeric[] | Vertical bars |
| 22 | gauge | Gauge | numeric | Arc gauge |
| 23 | radial_gauge | Radial Gauge | numeric | Full circle |
| 24 | progress_bar | Progress Bar | numeric | Horizontal fill |
| 25 | realtime_chart | Real-time Chart | numeric | Streaming line |
| 26 | min_max_avg | Min/Max/Avg | numeric | Three-value summary |

### D. Status Widgets
| # | Type ID | Display Name | Data Type | Display |
|---|---------|-------------|-----------|---------|
| 27 | device_status | Device Status | boolean | Online/offline |
| 28 | mqtt_status | MQTT Status | enum | Connection state |
| 29 | device_health | Device Health | composite | Multi-metric |
| 30 | alarm_indicator | Alarm | boolean | Active/clear |
| 31 | command_status | Command Status | enum | Pending/ack/done |
| 32 | last_seen | Last Seen | datetime | Relative time |

### E. Industrial Widgets
| # | Type ID | Display Name | Data Type | Display |
|---|---------|-------------|-----------|---------|
| 33 | machine_status | Machine Status | enum | Running/stopped/fault |
| 34 | tank_level | Tank Level | numeric | Visual tank fill |
| 35 | motor_status | Motor Status | composite | RPM + state |
| 36 | equipment_status | Equipment Status | enum | Multi-state indicator |
| 37 | alarm_panel | Alarm Panel | list | Active alarm list |

### F. Information Widgets
| # | Type ID | Display Name | Data Type | Display |
|---|---------|-------------|-----------|---------|
| 38 | text_widget | Text | static | Rich text display |
| 39 | markdown_widget | Markdown | static | Rendered markdown |
| 40 | clock_widget | Clock | time | Live clock |
| 41 | event_log | Event Log | list | Recent events |
| 42 | device_list | Device List | list | Device summary |

## Widget Interface

Every widget implements:

```dart
abstract class DashboardWidgetRenderer {
  Widget build(BuildContext context, DashboardWidget widget, WidgetDataState data);
}
```

Where `WidgetDataState` provides:
- Current value (from telemetry or static config)
- Loading state
- Error state
- Historical data (for charts)
- Device info (for status widgets)

## Configuration Schema

Each widget type defines its configuration schema:

```dart
{
  "data_source": { ... },  // What data to display
  "display": { ... },      // How to display it
  "thresholds": [ ... ],   // Alert thresholds
  "chart": { ... },        // Chart-specific options
  "range": { ... },        // Value range
  "command": { ... },      // Control widget command config
}
```

## Extension Points

New widgets can be added by:
1. Creating a widget renderer class
2. Registering it with the WidgetRegistry
3. No changes needed to the dashboard engine, editor, or data binding
