import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/virtual_devices/domain/entities/simulation_profile.dart';
import 'package:nexloza/features/virtual_devices/domain/entities/simulator_state.dart';
import 'package:nexloza/features/virtual_devices/domain/entities/digital_twin_state.dart';
import 'package:nexloza/features/virtual_devices/data/simulator_engine.dart';
import 'package:nexloza/features/devices/domain/entities/device_entity.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SimulationProfileType
  // ---------------------------------------------------------------------------
  group('SimulationProfileType', () {
    test('6 profile types are defined', () {
      expect(SimulationProfileType.values.length, 6);
    });

    test('fromString resolves known db values', () {
      expect(
        SimulationProfileType.fromString('smart_home'),
        SimulationProfileType.smartHome,
      );
      expect(
        SimulationProfileType.fromString('agriculture'),
        SimulationProfileType.agriculture,
      );
      expect(
        SimulationProfileType.fromString('weather_station'),
        SimulationProfileType.weatherStation,
      );
      expect(
        SimulationProfileType.fromString('energy_monitoring'),
        SimulationProfileType.energyMonitoring,
      );
      expect(
        SimulationProfileType.fromString('industrial_equipment'),
        SimulationProfileType.industrialEquipment,
      );
      expect(
        SimulationProfileType.fromString('water_management'),
        SimulationProfileType.waterManagement,
      );
    });

    test('fromString defaults to smartHome for unknown value', () {
      expect(
        SimulationProfileType.fromString('nonexistent'),
        SimulationProfileType.smartHome,
      );
    });

    test('dbValue round-trips through fromString', () {
      for (final type in SimulationProfileType.values) {
        expect(SimulationProfileType.fromString(type.dbValue), type);
      }
    });

    test('every type has displayName', () {
      for (final type in SimulationProfileType.values) {
        expect(type.displayName, isNotEmpty);
      }
    });

    test('every type has description', () {
      for (final type in SimulationProfileType.values) {
        expect(type.description, isNotEmpty);
      }
    });

    test('every type has icon', () {
      for (final type in SimulationProfileType.values) {
        expect(type.icon, isNotNull);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // SimulatedSensorDef
  // ---------------------------------------------------------------------------
  group('SimulatedSensorDef', () {
    test('stores all fields correctly', () {
      const def = SimulatedSensorDef(
        name: 'Test',
        sensorType: 'temperature',
        telemetryKey: 'temp',
        unit: '°C',
        minValue: 0,
        maxValue: 100,
        initialValue: 22,
      );
      expect(def.name, 'Test');
      expect(def.sensorType, 'temperature');
      expect(def.telemetryKey, 'temp');
      expect(def.unit, '°C');
      expect(def.minValue, 0);
      expect(def.maxValue, 100);
      expect(def.initialValue, 22);
      expect(def.updateIntervalMs, 5000);
    });

    test('custom updateIntervalMs', () {
      const def = SimulatedSensorDef(
        name: 'Fast',
        sensorType: 'custom',
        telemetryKey: 'fast',
        unit: '',
        minValue: 0,
        maxValue: 1,
        initialValue: 0,
        updateIntervalMs: 1000,
      );
      expect(def.updateIntervalMs, 1000);
    });
  });

  // ---------------------------------------------------------------------------
  // SimulatedActuatorDef
  // ---------------------------------------------------------------------------
  group('SimulatedActuatorDef', () {
    test('stores all fields correctly', () {
      const def = SimulatedActuatorDef(
        name: 'Fan',
        actuatorType: 'fan',
        controlType: 'slider',
        commandKey: 'fan_speed',
        minValue: 0,
        maxValue: 100,
        step: 5,
        initialValue: 0,
      );
      expect(def.name, 'Fan');
      expect(def.actuatorType, 'fan');
      expect(def.controlType, 'slider');
      expect(def.commandKey, 'fan_speed');
      expect(def.minValue, 0);
      expect(def.maxValue, 100);
      expect(def.step, 5);
      expect(def.initialValue, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // SimulationProfiles
  // ---------------------------------------------------------------------------
  group('SimulationProfiles', () {
    test('all returns 6 profiles', () {
      expect(SimulationProfiles.all.length, 6);
    });

    test('forType returns correct profile for each type', () {
      for (final type in SimulationProfileType.values) {
        final profile = SimulationProfiles.forType(type);
        expect(profile.profileType, type);
      }
    });

    test('smartHome has 4 sensors and 2 actuators', () {
      final p = SimulationProfiles.smartHome;
      expect(p.sensors.length, 4);
      expect(p.actuators.length, 2);
      expect(p.profileType, SimulationProfileType.smartHome);
    });

    test('agriculture has 4 sensors and 1 actuator', () {
      final p = SimulationProfiles.agriculture;
      expect(p.sensors.length, 4);
      expect(p.actuators.length, 1);
    });

    test('weatherStation has 5 sensors and 0 actuators', () {
      final p = SimulationProfiles.weatherStation;
      expect(p.sensors.length, 5);
      expect(p.actuators.length, 0);
    });

    test('energyMonitoring has 5 sensors and 0 actuators', () {
      final p = SimulationProfiles.energyMonitoring;
      expect(p.sensors.length, 5);
      expect(p.actuators.length, 0);
    });

    test('industrialEquipment has 4 sensors and 2 actuators', () {
      final p = SimulationProfiles.industrialEquipment;
      expect(p.sensors.length, 4);
      expect(p.actuators.length, 2);
    });

    test('waterManagement has 4 sensors and 2 actuators', () {
      final p = SimulationProfiles.waterManagement;
      expect(p.sensors.length, 4);
      expect(p.actuators.length, 2);
    });

    test('every sensor has valid range (min < max)', () {
      for (final profile in SimulationProfiles.all) {
        for (final s in profile.sensors) {
          expect(
            s.minValue,
            lessThan(s.maxValue),
            reason: '${profile.profileType.dbValue}/${s.telemetryKey}',
          );
        }
      }
    });

    test('every sensor initial value within range', () {
      for (final profile in SimulationProfiles.all) {
        for (final s in profile.sensors) {
          expect(
            s.initialValue,
            greaterThanOrEqualTo(s.minValue),
            reason: '${profile.profileType.dbValue}/${s.telemetryKey}',
          );
          expect(
            s.initialValue,
            lessThanOrEqualTo(s.maxValue),
            reason: '${profile.profileType.dbValue}/${s.telemetryKey}',
          );
        }
      }
    });

    test('every actuator has valid range', () {
      for (final profile in SimulationProfiles.all) {
        for (final a in profile.actuators) {
          expect(
            a.minValue,
            lessThanOrEqualTo(a.maxValue),
            reason: '${profile.profileType.dbValue}/${a.commandKey}',
          );
          expect(
            a.step,
            greaterThan(0),
            reason: '${profile.profileType.dbValue}/${a.commandKey}',
          );
        }
      }
    });

    test('telemetry keys are unique within each profile', () {
      for (final profile in SimulationProfiles.all) {
        final keys = profile.sensors.map((s) => s.telemetryKey).toSet();
        expect(
          keys.length,
          profile.sensors.length,
          reason: '${profile.profileType.dbValue} has duplicate keys',
        );
      }
    });

    test('command keys are unique within each profile', () {
      for (final profile in SimulationProfiles.all) {
        final keys = profile.actuators.map((a) => a.commandKey).toSet();
        expect(
          keys.length,
          profile.actuators.length,
          reason: '${profile.profileType.dbValue} has duplicate command keys',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // SimulatorStatus
  // ---------------------------------------------------------------------------
  group('SimulatorStatus', () {
    test('4 statuses are defined', () {
      expect(SimulatorStatus.values.length, 4);
    });

    test('fromString resolves known values', () {
      expect(SimulatorStatus.fromString('idle'), SimulatorStatus.idle);
      expect(SimulatorStatus.fromString('running'), SimulatorStatus.running);
      expect(SimulatorStatus.fromString('paused'), SimulatorStatus.paused);
      expect(SimulatorStatus.fromString('stopped'), SimulatorStatus.stopped);
    });

    test('fromString defaults to idle for unknown', () {
      expect(SimulatorStatus.fromString('unknown'), SimulatorStatus.idle);
    });

    test('every status has displayName', () {
      for (final s in SimulatorStatus.values) {
        expect(s.displayName, isNotEmpty);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // FaultScenario
  // ---------------------------------------------------------------------------
  group('FaultScenario', () {
    test('5 fault scenarios are defined', () {
      expect(FaultScenario.values.length, 5);
    });

    test('fromString resolves known db values', () {
      expect(
        FaultScenario.fromString('device_offline'),
        FaultScenario.deviceOffline,
      );
      expect(
        FaultScenario.fromString('sensor_failure'),
        FaultScenario.sensorFailure,
      );
      expect(
        FaultScenario.fromString('out_of_range'),
        FaultScenario.outOfRange,
      );
      expect(
        FaultScenario.fromString('network_interrupt'),
        FaultScenario.networkInterrupt,
      );
      expect(
        FaultScenario.fromString('command_timeout'),
        FaultScenario.commandTimeout,
      );
    });

    test('fromString defaults to deviceOffline for unknown', () {
      expect(FaultScenario.fromString('garbage'), FaultScenario.deviceOffline);
    });

    test('dbValue round-trips through fromString', () {
      for (final f in FaultScenario.values) {
        expect(FaultScenario.fromString(f.dbValue), f);
      }
    });

    test('every fault has displayName and description', () {
      for (final f in FaultScenario.values) {
        expect(f.displayName, isNotEmpty);
        expect(f.description, isNotEmpty);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // SimulatedSensorState
  // ---------------------------------------------------------------------------
  group('SimulatedSensorState', () {
    test('default isEnabled is true', () {
      const s = SimulatedSensorState(sensorKey: 'temp', currentValue: 22);
      expect(s.isEnabled, isTrue);
      expect(s.activeFault, isNull);
      expect(s.lastPublishedAt, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const original = SimulatedSensorState(
        sensorKey: 'temp',
        currentValue: 22,
        isEnabled: true,
      );
      final updated = original.copyWith(currentValue: 25);
      expect(updated.sensorKey, 'temp');
      expect(updated.currentValue, 25);
      expect(updated.isEnabled, isTrue);
    });

    test('copyWith sets activeFault', () {
      const s = SimulatedSensorState(sensorKey: 'x', currentValue: 0);
      final faulted = s.copyWith(activeFault: FaultScenario.sensorFailure);
      expect(faulted.activeFault, FaultScenario.sensorFailure);
    });

    test('copyWith clearFault removes activeFault', () {
      final s = const SimulatedSensorState(
        sensorKey: 'x',
        currentValue: 0,
      ).copyWith(activeFault: FaultScenario.outOfRange);
      expect(s.activeFault, FaultScenario.outOfRange);

      final cleared = s.copyWith(clearFault: true);
      expect(cleared.activeFault, isNull);
    });

    test('copyWith isEnabled toggle', () {
      const s = SimulatedSensorState(sensorKey: 'x', currentValue: 0);
      final disabled = s.copyWith(isEnabled: false);
      expect(disabled.isEnabled, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // SimulatorDeviceState
  // ---------------------------------------------------------------------------
  group('SimulatorDeviceState', () {
    test('defaults', () {
      const s = SimulatorDeviceState(deviceId: 'dev-1');
      expect(s.status, SimulatorStatus.idle);
      expect(s.speed, 1.0);
      expect(s.intervalMs, 5000);
      expect(s.sensors, isEmpty);
      expect(s.startedAt, isNull);
      expect(s.error, isNull);
    });

    test('copyWith status', () {
      const s = SimulatorDeviceState(deviceId: 'dev-1');
      final running = s.copyWith(status: SimulatorStatus.running);
      expect(running.status, SimulatorStatus.running);
      expect(running.deviceId, 'dev-1');
    });

    test('copyWith clearStartedAt', () {
      final s = SimulatorDeviceState(
        deviceId: 'dev-1',
        startedAt: DateTime(2026, 1, 1),
      );
      expect(s.startedAt, isNotNull);
      final cleared = s.copyWith(clearStartedAt: true);
      expect(cleared.startedAt, isNull);
    });

    test('copyWith clearError', () {
      const s = SimulatorDeviceState(deviceId: 'dev-1', error: 'boom');
      final cleared = s.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('copyWith speed and intervalMs', () {
      const s = SimulatorDeviceState(deviceId: 'dev-1');
      final fast = s.copyWith(speed: 5.0, intervalMs: 2000);
      expect(fast.speed, 5.0);
      expect(fast.intervalMs, 2000);
    });
  });

  // ---------------------------------------------------------------------------
  // TwinSyncStatus
  // ---------------------------------------------------------------------------
  group('TwinSyncStatus', () {
    test('4 statuses defined', () {
      expect(TwinSyncStatus.values.length, 4);
    });

    test('fromString resolves known values', () {
      expect(TwinSyncStatus.fromString('synced'), TwinSyncStatus.synced);
      expect(TwinSyncStatus.fromString('pending'), TwinSyncStatus.pending);
      expect(TwinSyncStatus.fromString('failed'), TwinSyncStatus.failed);
      expect(TwinSyncStatus.fromString('stale'), TwinSyncStatus.stale);
    });

    test('fromString defaults to synced for unknown', () {
      expect(TwinSyncStatus.fromString('nope'), TwinSyncStatus.synced);
    });

    test('every status has displayName', () {
      for (final s in TwinSyncStatus.values) {
        expect(s.displayName, isNotEmpty);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // TwinAttribute
  // ---------------------------------------------------------------------------
  group('TwinAttribute', () {
    test('fromJson and toJson round-trip', () {
      final now = DateTime.utc(2026, 11, 1, 12, 0, 0);
      final attr = TwinAttribute(key: 'fan_speed', value: 50, updatedAt: now);
      final json = attr.toJson();
      expect(json['key'], 'fan_speed');
      expect(json['value'], 50);

      final restored = TwinAttribute.fromJson(json);
      expect(restored.key, 'fan_speed');
      expect(restored.value, 50);
      expect(restored.updatedAt, now);
    });
  });

  // ---------------------------------------------------------------------------
  // DigitalTwinState
  // ---------------------------------------------------------------------------
  group('DigitalTwinState', () {
    final now = DateTime.utc(2026, 11, 1, 12, 0, 0);

    DigitalTwinState makeTwin({
      Map<String, dynamic> reported = const {},
      Map<String, dynamic> desired = const {},
      TwinSyncStatus syncStatus = TwinSyncStatus.synced,
    }) {
      return DigitalTwinState(
        id: 'twin-1',
        deviceId: 'dev-1',
        reportedState: reported,
        desiredState: desired,
        syncStatus: syncStatus,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('defaults', () {
      final twin = makeTwin();
      expect(twin.reportedState, isEmpty);
      expect(twin.desiredState, isEmpty);
      expect(twin.reportedVersion, 0);
      expect(twin.desiredVersion, 0);
      expect(twin.syncStatus, TwinSyncStatus.synced);
      expect(twin.isInSync, isTrue);
    });

    test('isInSync returns false when not synced', () {
      final twin = makeTwin(syncStatus: TwinSyncStatus.pending);
      expect(twin.isInSync, isFalse);
    });

    test('getMismatches returns empty when states match', () {
      final twin = makeTwin(
        reported: {'fan_speed': 50, 'mode': 'auto'},
        desired: {'fan_speed': 50, 'mode': 'auto'},
      );
      expect(twin.getMismatches(), isEmpty);
    });

    test('getMismatches returns keys that differ', () {
      final twin = makeTwin(
        reported: {'fan_speed': 50, 'mode': 'auto'},
        desired: {'fan_speed': 80, 'mode': 'auto'},
      );
      expect(twin.getMismatches(), ['fan_speed']);
    });

    test('getMismatches includes keys present in only one state', () {
      final twin = makeTwin(
        reported: {'fan_speed': 50},
        desired: {'fan_speed': 50, 'mode': 'eco'},
      );
      final mismatches = twin.getMismatches();
      expect(mismatches, contains('mode'));
    });

    test('fromJson parses all fields', () {
      final json = {
        'id': 'twin-1',
        'device_id': 'dev-1',
        'reported_state': {'temp': 22.5},
        'desired_state': {'temp': 24.0},
        'reported_version': 3,
        'desired_version': 4,
        'reported_at': '2026-11-01T12:00:00.000Z',
        'desired_at': '2026-11-01T12:05:00.000Z',
        'sync_status': 'pending',
        'last_sync_at': '2026-11-01T11:55:00.000Z',
        'created_at': '2026-11-01T10:00:00.000Z',
        'updated_at': '2026-11-01T12:05:00.000Z',
      };
      final twin = DigitalTwinState.fromJson(json);
      expect(twin.id, 'twin-1');
      expect(twin.deviceId, 'dev-1');
      expect(twin.reportedState['temp'], 22.5);
      expect(twin.desiredState['temp'], 24.0);
      expect(twin.reportedVersion, 3);
      expect(twin.desiredVersion, 4);
      expect(twin.reportedAt, isNotNull);
      expect(twin.desiredAt, isNotNull);
      expect(twin.syncStatus, TwinSyncStatus.pending);
      expect(twin.lastSyncAt, isNotNull);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'twin-2',
        'device_id': 'dev-2',
        'created_at': '2026-11-01T10:00:00.000Z',
        'updated_at': '2026-11-01T10:00:00.000Z',
      };
      final twin = DigitalTwinState.fromJson(json);
      expect(twin.reportedState, isEmpty);
      expect(twin.desiredState, isEmpty);
      expect(twin.reportedVersion, 0);
      expect(twin.reportedAt, isNull);
      expect(twin.desiredAt, isNull);
      expect(twin.lastSyncAt, isNull);
      expect(twin.syncStatus, TwinSyncStatus.synced);
    });

    test('toJson includes correct keys', () {
      final twin = makeTwin(reported: {'a': 1}, desired: {'a': 2});
      final json = twin.toJson();
      expect(json['device_id'], 'dev-1');
      expect(json['reported_state'], {'a': 1});
      expect(json['desired_state'], {'a': 2});
      expect(json.containsKey('sync_status'), isTrue);
    });

    test('copyWith updates selected fields', () {
      final twin = makeTwin();
      final updated = twin.copyWith(
        syncStatus: TwinSyncStatus.failed,
        reportedVersion: 5,
      );
      expect(updated.syncStatus, TwinSyncStatus.failed);
      expect(updated.reportedVersion, 5);
      expect(updated.id, 'twin-1');
    });
  });

  // ---------------------------------------------------------------------------
  // SimulatorEngine
  // ---------------------------------------------------------------------------
  group('SimulatorEngine', () {
    late SimulatorEngine engine;

    setUp(() {
      engine = SimulatorEngine();
    });

    tearDown(() {
      engine.dispose();
    });

    test('getState returns null before start', () {
      expect(engine.getState('dev-1'), isNull);
    });

    test('startSimulation initializes sensors from profile', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
        seed: 42,
      );
      final state = engine.getState('dev-1');
      expect(state, isNotNull);
      expect(state!.status, SimulatorStatus.running);
      expect(state.sensors.length, 4);
      expect(state.sensors.containsKey('temperature'), isTrue);
      expect(state.sensors.containsKey('humidity'), isTrue);
      expect(state.sensors.containsKey('light_level'), isTrue);
      expect(state.sensors.containsKey('motion'), isTrue);
    });

    test('startSimulation sets initial values from sensor defs', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
        seed: 42,
      );
      final state = engine.getState('dev-1')!;
      expect(state.sensors['temperature']!.currentValue, 22);
      expect(state.sensors['humidity']!.currentValue, 55);
      expect(state.sensors['light_level']!.currentValue, 400);
      expect(state.sensors['motion']!.currentValue, 0);
    });

    test('duplicate startSimulation is ignored', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );
      final startedAt1 = engine.getState('dev-1')!.startedAt;
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );
      final startedAt2 = engine.getState('dev-1')!.startedAt;
      expect(startedAt1, startedAt2);
    });

    test('pauseSimulation transitions running to paused', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );
      engine.pauseSimulation('dev-1');
      expect(engine.getState('dev-1')!.status, SimulatorStatus.paused);
    });

    test('pauseSimulation ignores non-running', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );
      engine.stopSimulation('dev-1');
      engine.pauseSimulation('dev-1');
      expect(engine.getState('dev-1')!.status, SimulatorStatus.stopped);
    });

    test('resumeSimulation transitions paused to running', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );
      engine.pauseSimulation('dev-1');
      engine.resumeSimulation('dev-1');
      expect(engine.getState('dev-1')!.status, SimulatorStatus.running);
    });

    test('resumeSimulation ignores non-paused', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );
      engine.resumeSimulation('dev-1');
      expect(engine.getState('dev-1')!.status, SimulatorStatus.running);
    });

    test('stopSimulation transitions to stopped', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );
      engine.stopSimulation('dev-1');
      expect(engine.getState('dev-1')!.status, SimulatorStatus.stopped);
    });

    test('resetSimulation returns to idle with initial values', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
        seed: 42,
      );
      engine.resetSimulation('dev-1');
      final state = engine.getState('dev-1')!;
      expect(state.status, SimulatorStatus.idle);
      expect(state.sensors['temperature']!.currentValue, 22);
      expect(state.sensors['humidity']!.currentValue, 55);
    });

    test('setSpeed clamps to 0.5-10.0', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );
      engine.setSpeed('dev-1', 0.1);
      expect(engine.getState('dev-1')!.speed, 0.5);
      engine.setSpeed('dev-1', 99);
      expect(engine.getState('dev-1')!.speed, 10.0);
      engine.setSpeed('dev-1', 5.0);
      expect(engine.getState('dev-1')!.speed, 5.0);
    });

    test('setInterval clamps to 1000-60000', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );
      engine.setInterval('dev-1', 100);
      expect(engine.getState('dev-1')!.intervalMs, 1000);
      engine.setInterval('dev-1', 100000);
      expect(engine.getState('dev-1')!.intervalMs, 60000);
      engine.setInterval('dev-1', 3000);
      expect(engine.getState('dev-1')!.intervalMs, 3000);
    });

    test('enableFault and disableFault', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
        seed: 42,
      );
      engine.enableFault('dev-1', 'temperature', FaultScenario.outOfRange);
      expect(
        engine.getState('dev-1')!.sensors['temperature']!.activeFault,
        FaultScenario.outOfRange,
      );

      engine.disableFault('dev-1', 'temperature');
      expect(
        engine.getState('dev-1')!.sensors['temperature']!.activeFault,
        isNull,
      );
    });

    test('enableFault ignores unknown sensor', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );
      engine.enableFault('dev-1', 'nonexistent', FaultScenario.sensorFailure);
      final state = engine.getState('dev-1')!;
      expect(state.sensors.values.every((s) => s.activeFault == null), isTrue);
    });

    test('setSensorEnabled toggles sensor', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );
      engine.setSensorEnabled('dev-1', 'humidity', false);
      expect(engine.getState('dev-1')!.sensors['humidity']!.isEnabled, isFalse);
      engine.setSensorEnabled('dev-1', 'humidity', true);
      expect(engine.getState('dev-1')!.sensors['humidity']!.isEnabled, isTrue);
    });

    test('remote actuator value is applied only while responsive', () {
      engine.startSimulation(
        deviceId: 'command',
        profile: SimulationProfiles.smartHome,
      );
      expect(engine.applyActuatorValue('command', 'fan_speed', 60), 60);
      engine.pauseSimulation('command');
      expect(engine.applyActuatorValue('command', 'fan_speed', 80), isNull);
      engine.resumeSimulation('command');
      engine.enableFault(
        'command',
        'temperature',
        FaultScenario.commandTimeout,
      );
      expect(engine.applyActuatorValue('command', 'fan_speed', 80), isNull);
      expect(engine.applyActuatorValue('missing', 'fan_speed', 80), isNull);
    });

    test('handleActuatorCommand stores value', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );
      engine.handleActuatorCommand('dev-1', 'fan_speed', 75);
      final values = engine.getLatestValues('dev-1');
      expect(values, isNotEmpty);
    });

    test('getLatestValues returns sensor values', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
        seed: 42,
      );
      final values = engine.getLatestValues('dev-1');
      expect(values.length, 4);
      expect(values['temperature'], 22);
      expect(values['humidity'], 55);
    });

    test('getLatestValues returns empty for unknown device', () {
      expect(engine.getLatestValues('unknown'), isEmpty);
    });

    test('stateStream emits on start', () async {
      final completer = Completer<SimulatorDeviceState>();
      final sub = engine.stateStream.listen((s) {
        if (!completer.isCompleted) completer.complete(s);
      });

      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );

      final emitted = await completer.future.timeout(
        const Duration(seconds: 2),
      );
      expect(emitted.deviceId, 'dev-1');
      expect(emitted.status, SimulatorStatus.running);
      await sub.cancel();
    });

    test('stateStream emits on pause', () async {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );

      final states = <SimulatorDeviceState>[];
      final sub = engine.stateStream.listen(states.add);

      engine.pauseSimulation('dev-1');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.any((s) => s.status == SimulatorStatus.paused), isTrue);
      await sub.cancel();
    });

    test('multiple devices can run independently', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
        seed: 1,
      );
      engine.startSimulation(
        deviceId: 'dev-2',
        profile: SimulationProfiles.agriculture,
        seed: 2,
      );

      expect(engine.getState('dev-1')!.sensors.length, 4);
      expect(engine.getState('dev-2')!.sensors.length, 4);
      expect(
        engine.getState('dev-1')!.sensors.containsKey('temperature'),
        isTrue,
      );
      expect(
        engine.getState('dev-2')!.sensors.containsKey('soil_moisture'),
        isTrue,
      );
    });

    test('industrialEquipment profile initializes correctly', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.industrialEquipment,
        seed: 42,
      );
      final state = engine.getState('dev-1')!;
      expect(state.sensors.containsKey('motor_temp'), isTrue);
      expect(state.sensors.containsKey('vibration'), isTrue);
      expect(state.sensors.containsKey('rpm'), isTrue);
      expect(state.sensors.containsKey('pressure'), isTrue);
      expect(state.sensors['motor_temp']!.currentValue, 45);
      expect(state.sensors['vibration']!.currentValue, 2.5);
      expect(state.sensors['rpm']!.currentValue, 1800);
    });

    test('waterManagement profile initializes correctly', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.waterManagement,
        seed: 42,
      );
      final state = engine.getState('dev-1')!;
      expect(state.sensors.containsKey('tank_level'), isTrue);
      expect(state.sensors.containsKey('flow_rate'), isTrue);
      expect(state.sensors.containsKey('water_pressure'), isTrue);
      expect(state.sensors.containsKey('leak_detected'), isTrue);
      expect(state.sensors['tank_level']!.currentValue, 75);
    });

    test('energyMonitoring profile initializes correctly', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.energyMonitoring,
        seed: 42,
      );
      final state = engine.getState('dev-1')!;
      expect(state.sensors.containsKey('voltage'), isTrue);
      expect(state.sensors.containsKey('current'), isTrue);
      expect(state.sensors.containsKey('power'), isTrue);
      expect(state.sensors.containsKey('energy'), isTrue);
      expect(state.sensors.containsKey('power_factor'), isTrue);
      expect(state.sensors['voltage']!.currentValue, 230);
    });

    test('weatherStation profile initializes correctly', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.weatherStation,
        seed: 42,
      );
      final state = engine.getState('dev-1')!;
      expect(state.sensors.length, 5);
      expect(state.sensors.containsKey('pressure'), isTrue);
      expect(state.sensors.containsKey('wind_speed'), isTrue);
      expect(state.sensors.containsKey('rainfall'), isTrue);
    });

    test('dispose cancels timers and clears state', () {
      engine.startSimulation(
        deviceId: 'dev-1',
        profile: SimulationProfiles.smartHome,
      );
      engine.dispose();
      expect(engine.getState('dev-1'), isNull);
      expect(engine.getLatestValues('dev-1'), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Device entity virtual fields
  // ---------------------------------------------------------------------------
  group('Device entity virtual fields', () {
    test('isVirtual defaults to false', () {
      final device = Device(
        id: 'dev-1',
        projectId: 'proj-1',
        name: 'Test',
        deviceType: 'sensor',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(device.isVirtual, isFalse);
      expect(device.simulationProfile, isNull);
    });

    test('fromJson parses is_virtual and simulation_profile', () {
      final json = {
        'id': 'dev-1',
        'project_id': 'proj-1',
        'name': 'Virtual Sensor',
        'device_type': 'sensor',
        'hardware_platform': 'genericMqtt',
        'is_online': true,
        'is_virtual': true,
        'simulation_profile': 'smart_home',
        'metadata': <String, dynamic>{},
        'created_at': '2026-11-01T12:00:00.000Z',
        'updated_at': '2026-11-01T12:00:00.000Z',
      };
      final device = Device.fromJson(json);
      expect(device.isVirtual, isTrue);
      expect(device.simulationProfile, 'smart_home');
      expect(device.hardwarePlatform, HardwarePlatform.genericMqtt);
    });

    test('fromJson defaults is_virtual to false when absent', () {
      final json = {
        'id': 'dev-2',
        'project_id': 'proj-1',
        'name': 'Physical',
        'device_type': 'sensor',
        'metadata': <String, dynamic>{},
        'created_at': '2026-11-01T12:00:00.000Z',
        'updated_at': '2026-11-01T12:00:00.000Z',
      };
      final device = Device.fromJson(json);
      expect(device.isVirtual, isFalse);
      expect(device.simulationProfile, isNull);
    });

    test('toJson includes is_virtual and simulation_profile', () {
      final device = Device(
        id: 'dev-1',
        projectId: 'proj-1',
        name: 'Virtual',
        deviceType: 'sensor',
        isVirtual: true,
        simulationProfile: 'agriculture',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final json = device.toJson();
      expect(json['is_virtual'], isTrue);
      expect(json['simulation_profile'], 'agriculture');
    });
  });

  // ---------------------------------------------------------------------------
  // HardwarePlatform
  // ---------------------------------------------------------------------------
  group('HardwarePlatform', () {
    test('genericMqtt displayName', () {
      expect(HardwarePlatform.genericMqtt.displayName, 'Generic MQTT');
    });

    test('fromString resolves genericMqtt', () {
      expect(
        HardwarePlatform.fromString('genericMqtt'),
        HardwarePlatform.genericMqtt,
      );
    });

    test('fromString defaults to other for unknown', () {
      expect(HardwarePlatform.fromString('xyzzy'), HardwarePlatform.other);
    });
  });
}
