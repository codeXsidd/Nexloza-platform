# Data Binding Guide

## Overview

The NEXLOZA data binding engine connects dashboard widgets to live device telemetry through a universal `DataSource` model and the `TelemetryDataService`.

## DataSource Model

```dart
class DataSource {
  final String? projectId;
  final String? deviceId;
  final String? sensorKey;
  final String? actuatorKey;
  final String? telemetryKey;
}
```

### Binding Hierarchy

1. **Project** — Scopes device selection to a specific project
2. **Device** — The physical or virtual IoT device
3. **Sensor/Actuator** — The specific data channel on the device
4. **Telemetry Key** — The key used in the telemetry table (defaults to sensorKey or actuatorKey)

### Key Properties

- `isBound` — Returns `true` when `deviceId` AND (`sensorKey` OR `actuatorKey`) are set
- `effectiveKey` — Priority: `telemetryKey` > `sensorKey` > `actuatorKey`
- `hasDevice` / `hasSensor` / `hasActuator` — Individual field checks

## DataSourceSelector Widget

The `DataSourceSelector` is a Riverpod `ConsumerStatefulWidget` that provides cascading dropdown selection:

```dart
DataSourceSelector(
  dataSource: widget.dataSource,
  onChanged: (ds) => setState(() => _dataSource = ds),
)
```

### Cascading Behavior

1. **Project dropdown** — Lists all projects from `projectsProvider`
2. **Device dropdown** — Appears when a project is selected. Shows online/offline status indicators. Reads from `projectDevicesProvider(projectId)`
3. **Sensor dropdown** — Appears when a device is selected. Shows telemetry keys. Reads from `deviceSensorsProvider(deviceId)`
4. **Actuator dropdown** — Also appears when a device is selected. Shows command keys. Reads from `deviceActuatorsProvider(deviceId)`
5. **Binding chip** — Shows the effective key when fully bound

### Persistence

The DataSource is stored in the widget's `config` JSONB column:

```json
{
  "data_source": {
    "project_id": "uuid",
    "device_id": "uuid",
    "sensor_key": "temperature",
    "telemetry_key": "temperature"
  }
}
```

## TelemetryDataService

Manages shared, reference-counted Supabase Realtime subscriptions.

### Reference Counting

```
subscribe("device-1", "temperature")  → refcount = 1, starts stream
subscribe("device-1", "temperature")  → refcount = 2, reuses stream
unsubscribe("device-1", "temperature") → refcount = 1, keeps stream
unsubscribe("device-1", "temperature") → refcount = 0, closes stream
```

### API

```dart
// Subscribe to live updates
Stream<TelemetryReading> subscribe(String deviceId, String sensorKey)

// Decrement reference count (cleans up at 0)
void unsubscribe(String deviceId, String sensorKey)

// Get cached latest value (no network call)
TelemetryReading? getLatest(String deviceId, String sensorKey)

// Query historical data
Future<List<TelemetryReading>> getHistory({
  required String deviceId,
  required String sensorKey,
  required DateTime from,
  required DateTime to,
  int limit = 500,
})

// Get latest reading for each sensor on a device
Future<Map<String, TelemetryReading>> getLatestForDevice(String deviceId)
```

### Lifecycle

The service is provided via Riverpod and automatically disposed when the provider scope is destroyed:

```dart
final telemetryDataServiceProvider = Provider<TelemetryDataService>((ref) {
  final service = TelemetryDataService(ref.watch(supabaseClientProvider));
  ref.onDispose(() => service.dispose());
  return service;
});
```

## Security

- No privileged MQTT credentials exposed in Flutter
- All telemetry access goes through Supabase RLS policies
- Widget data binding does not grant access beyond the user's project membership
