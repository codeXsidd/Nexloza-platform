# Phase 7 Testing

## Overview

Phase 7 adds comprehensive tests for the Virtual Device and Digital Twin system. All tests are in `app/test/phase7_test.dart` and are designed to run without external dependencies (no Supabase, no MQTT broker, no Android Emulator).

## Test Categories

### SimulationProfileType (6 tests)

- 6 profile types are defined
- `fromString` resolves all known db values
- `fromString` defaults to `smartHome` for unknown values
- `dbValue` round-trips through `fromString`
- Every type has a `displayName`
- Every type has an `icon`

### SimulatedSensorDef (2 tests)

- All fields stored correctly
- Custom `updateIntervalMs` override

### SimulatedActuatorDef (1 test)

- All fields stored correctly

### SimulationProfiles (10 tests)

- `all` returns 6 profiles
- `forType` returns correct profile for each type
- Each profile has the correct number of sensors and actuators:
  - Smart Home: 4 sensors, 2 actuators
  - Agriculture: 4 sensors, 1 actuator
  - Weather Station: 5 sensors, 0 actuators
  - Energy Monitoring: 5 sensors, 0 actuators
  - Industrial Equipment: 4 sensors, 2 actuators
  - Water Management: 4 sensors, 2 actuators
- Every sensor has valid range (min < max)
- Every sensor initial value is within range
- Every actuator has valid range and step > 0
- Telemetry keys are unique within each profile
- Command keys are unique within each profile

### SimulatorStatus (4 tests)

- 4 statuses defined
- `fromString` resolves known values
- `fromString` defaults to `idle` for unknown
- Every status has `displayName`

### FaultScenario (5 tests)

- 5 fault scenarios defined
- `fromString` resolves known db values
- `fromString` defaults to `deviceOffline` for unknown
- `dbValue` round-trips through `fromString`
- Every fault has `displayName` and `description`

### SimulatedSensorState (5 tests)

- Default `isEnabled` is true, `activeFault` is null
- `copyWith` preserves unchanged fields
- `copyWith` sets `activeFault`
- `copyWith` with `clearFault` removes `activeFault`
- `copyWith` toggles `isEnabled`

### SimulatorDeviceState (5 tests)

- Defaults (idle, speed 1.0, interval 5000ms)
- `copyWith` updates status
- `copyWith` with `clearStartedAt`
- `copyWith` with `clearError`
- `copyWith` updates speed and intervalMs

### TwinSyncStatus (4 tests)

- 4 statuses defined
- `fromString` resolves known values
- `fromString` defaults to `synced` for unknown
- Every status has `displayName`

### TwinAttribute (1 test)

- `fromJson` and `toJson` round-trip correctly

### DigitalTwinState (8 tests)

- Default values (empty states, version 0, synced)
- `isInSync` returns false when not synced
- `getMismatches` returns empty when states match
- `getMismatches` returns keys that differ
- `getMismatches` includes keys present in only one state
- `fromJson` parses all fields
- `fromJson` handles null optional fields
- `toJson` includes correct keys
- `copyWith` updates selected fields

### SimulatorEngine (22 tests)

- `getState` returns null before start
- `startSimulation` initializes sensors from profile
- `startSimulation` sets initial values from sensor defs
- Duplicate `startSimulation` is ignored
- `pauseSimulation` transitions running to paused
- `pauseSimulation` ignores non-running
- `resumeSimulation` transitions paused to running
- `resumeSimulation` ignores non-paused
- `stopSimulation` transitions to stopped
- `resetSimulation` returns to idle with initial values
- `setSpeed` clamps to 0.5–10.0
- `setInterval` clamps to 1000–60000
- `enableFault` and `disableFault` work correctly
- `enableFault` ignores unknown sensor
- `setSensorEnabled` toggles sensor
- `handleActuatorCommand` stores value
- `getLatestValues` returns sensor values
- `getLatestValues` returns empty for unknown device
- `stateStream` emits on start
- `stateStream` emits on pause
- Multiple devices can run independently
- Profile-specific initialization (industrial, water, energy, weather)
- `dispose` cancels timers and closes stream

### Device Entity Virtual Fields (4 tests)

- `isVirtual` defaults to false
- `fromJson` parses `is_virtual` and `simulation_profile`
- `fromJson` defaults `is_virtual` to false when absent
- `toJson` includes `is_virtual` and `simulation_profile`

### HardwarePlatform (3 tests)

- `genericMqtt` has correct `displayName`
- `fromString` resolves `genericMqtt`
- `fromString` defaults to `other` for unknown values

## Running Tests

```bash
cd app
flutter test test/phase7_test.dart
```

To run all tests including prior phases:

```bash
cd app
flutter test
```

## Test Design Principles

1. **No external dependencies.** Tests do not require Supabase, NanoMQ, or an Android Emulator. All tested code uses in-memory state.

2. **Deterministic values.** `SimulatorEngine.startSimulation()` accepts an optional `seed` parameter. Tests use fixed seeds to get reproducible value sequences.

3. **No mocked tests claimed as integration tests.** These are unit tests for domain entities and the simulator engine. Repository tests that would require Supabase are not included and are not claimed as integration tests.

4. **Preserves existing tests.** Phase 7 tests are in a separate file (`phase7_test.dart`). The 403 existing tests from Phases 1–6 are untouched.

5. **No hidden or skipped tests.** All tests run and are expected to pass. No `skip:` annotations are used.

## Limitations

- Repository classes (`VirtualDeviceRepository`, `DigitalTwinRepository`, `TelemetryPublisher`) require Supabase and MQTT connections and are not unit tested in this file. They would require integration test infrastructure.
- UI widget tests for the 4 new screens are not included. Widget tests would require mock providers and navigation setup.
- Android Emulator validation has not been performed for the complete virtual device flow.
- Phase 4 firmware has NOT been compiled with PlatformIO or physically tested on hardware.
