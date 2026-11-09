import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/core/services/mqtt_service.dart';
import 'package:nexloza/features/devices/domain/entities/actuator_entity.dart';
import 'package:nexloza/features/devices/domain/entities/sensor_entity.dart';
import 'package:nexloza/features/devices/domain/entities/device_entity.dart';
import 'package:nexloza/features/projects/domain/entities/project_entity.dart';
import 'package:nexloza/routing/route_names.dart';

void main() {
  group('ProjectTemplate', () {
    test('templates list has 9 entries', () {
      expect(ProjectTemplate.templates.length, 9);
    });

    test('each template has a non-empty name, description, category', () {
      for (final t in ProjectTemplate.templates) {
        expect(t.name.isNotEmpty, true, reason: 'template name is empty');
        expect(
          t.description.isNotEmpty,
          true,
          reason: '${t.name} description is empty',
        );
        expect(
          t.category.isNotEmpty,
          true,
          reason: '${t.name} category is empty',
        );
      }
    });

    test('template categories match Project.categories', () {
      for (final t in ProjectTemplate.templates) {
        expect(
          Project.categories,
          contains(t.category),
          reason: '${t.category} not in Project.categories',
        );
      }
    });

    test('Custom Project template exists', () {
      final custom = ProjectTemplate.templates.where(
        (t) => t.name == 'Custom Project',
      );
      expect(custom.length, 1);
      expect(custom.first.category, 'Custom');
    });
  });

  group('Project.categoryIcon', () {
    test('returns specific icon for each known category', () {
      expect(Project.categoryIcon('Smart Home'), Icons.home_outlined);
      expect(Project.categoryIcon('Smart Agriculture'), Icons.grass_outlined);
      expect(
        Project.categoryIcon('Smart Irrigation'),
        Icons.water_drop_outlined,
      );
      expect(Project.categoryIcon('Weather Monitoring'), Icons.cloud_outlined);
      expect(Project.categoryIcon('Water Management'), Icons.waves_outlined);
      expect(Project.categoryIcon('Energy Monitoring'), Icons.bolt_outlined);
      expect(Project.categoryIcon('Industrial IoT'), Icons.factory_outlined);
      expect(
        Project.categoryIcon('Security Monitoring'),
        Icons.shield_outlined,
      );
    });

    test('returns folder icon for unknown category', () {
      expect(Project.categoryIcon('Unknown'), Icons.folder_outlined);
      expect(Project.categoryIcon(null), Icons.folder_outlined);
    });
  });

  group('ActuatorType', () {
    test('fromString parses all known types', () {
      expect(ActuatorType.fromString('relay'), ActuatorType.relay);
      expect(ActuatorType.fromString('light'), ActuatorType.light);
      expect(ActuatorType.fromString('fan'), ActuatorType.fan);
      expect(ActuatorType.fromString('pump'), ActuatorType.pump);
      expect(ActuatorType.fromString('motor'), ActuatorType.motor);
      expect(ActuatorType.fromString('servo'), ActuatorType.servo);
      expect(ActuatorType.fromString('buzzer'), ActuatorType.buzzer);
      expect(ActuatorType.fromString('switch'), ActuatorType.switchType);
      expect(ActuatorType.fromString('smart_plug'), ActuatorType.smartPlug);
      expect(ActuatorType.fromString('valve'), ActuatorType.valve);
      expect(ActuatorType.fromString('heater'), ActuatorType.heater);
      expect(ActuatorType.fromString('cooler'), ActuatorType.cooler);
      expect(ActuatorType.fromString('lock'), ActuatorType.lock);
      expect(ActuatorType.fromString('rgb_led'), ActuatorType.rgbLed);
      expect(ActuatorType.fromString('display'), ActuatorType.display);
      expect(ActuatorType.fromString('custom'), ActuatorType.custom);
    });

    test('fromString returns custom for unknown', () {
      expect(ActuatorType.fromString('unknown'), ActuatorType.custom);
    });

    test('dbValue round-trips through fromString', () {
      for (final t in ActuatorType.values) {
        expect(ActuatorType.fromString(t.dbValue), t);
      }
    });

    test('all values have displayName', () {
      for (final t in ActuatorType.values) {
        expect(t.displayName.isNotEmpty, true);
      }
    });
  });

  group('ControlType', () {
    test('fromString parses all known types', () {
      expect(ControlType.fromString('toggle'), ControlType.toggle);
      expect(ControlType.fromString('slider'), ControlType.slider);
      expect(ControlType.fromString('numeric'), ControlType.numeric);
      expect(ControlType.fromString('multi_level'), ControlType.multiLevel);
      expect(ControlType.fromString('color'), ControlType.color);
      expect(ControlType.fromString('custom'), ControlType.custom);
    });

    test('fromString returns toggle for unknown', () {
      expect(ControlType.fromString('unknown'), ControlType.toggle);
    });

    test('dbValue round-trips through fromString', () {
      for (final t in ControlType.values) {
        expect(ControlType.fromString(t.dbValue), t);
      }
    });

    test('all values have displayName', () {
      for (final t in ControlType.values) {
        expect(t.displayName.isNotEmpty, true);
      }
    });
  });

  group('ActuatorDefinition', () {
    final json = <String, dynamic>{
      'id': 'a1',
      'device_id': 'd1',
      'project_id': 'p1',
      'name': 'Main Relay',
      'actuator_type': 'relay',
      'control_type': 'toggle',
      'telemetry_key': 'relay_state',
      'command_key': 'relay_1',
      'min_value': 0,
      'max_value': 1,
      'step': 1,
      'current_state': <String, dynamic>{'is_on': true, 'value': 1.0},
      'safety_limits': <String, dynamic>{},
      'is_active': true,
      'metadata': <String, dynamic>{},
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-02T00:00:00Z',
    };

    test('fromJson parses correctly', () {
      final actuator = ActuatorDefinition.fromJson(json);
      expect(actuator.id, 'a1');
      expect(actuator.deviceId, 'd1');
      expect(actuator.name, 'Main Relay');
      expect(actuator.actuatorType, ActuatorType.relay);
      expect(actuator.controlType, ControlType.toggle);
      expect(actuator.commandKey, 'relay_1');
      expect(actuator.telemetryKey, 'relay_state');
      expect(actuator.minValue, 0);
      expect(actuator.maxValue, 1);
      expect(actuator.step, 1);
      expect(actuator.isActive, true);
    });

    test('isOn reads from currentState', () {
      final actuator = ActuatorDefinition.fromJson(json);
      expect(actuator.isOn, true);
    });

    test('currentValue reads from currentState', () {
      final actuator = ActuatorDefinition.fromJson(json);
      expect(actuator.currentValue, 1.0);
    });

    test('fromJson handles missing optional fields', () {
      final minimal = <String, dynamic>{
        'id': 'a2',
        'device_id': 'd1',
        'project_id': 'p1',
        'name': 'Fan',
        'actuator_type': 'fan',
        'control_type': 'slider',
        'command_key': 'fan_1',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };
      final actuator = ActuatorDefinition.fromJson(minimal);
      expect(actuator.telemetryKey, isNull);
      expect(actuator.minValue, 0);
      expect(actuator.maxValue, 1);
      expect(actuator.step, 1);
      expect(actuator.currentState, isEmpty);
      expect(actuator.isOn, false);
      expect(actuator.currentValue, 0);
    });

    test('toJson produces expected keys', () {
      final actuator = ActuatorDefinition.fromJson(json);
      final output = actuator.toJson();
      expect(output['name'], 'Main Relay');
      expect(output['actuator_type'], 'relay');
      expect(output['control_type'], 'toggle');
      expect(output['command_key'], 'relay_1');
      expect(output.containsKey('id'), false);
    });
  });

  group('SensorType', () {
    test('fromString parses known types', () {
      expect(SensorType.fromString('temperature'), SensorType.temperature);
      expect(SensorType.fromString('humidity'), SensorType.humidity);
      expect(SensorType.fromString('pressure'), SensorType.pressure);
      expect(SensorType.fromString('soil_moisture'), SensorType.soilMoisture);
      expect(SensorType.fromString('light'), SensorType.light);
      expect(SensorType.fromString('gas'), SensorType.gas);
      expect(SensorType.fromString('motion'), SensorType.motion);
    });

    test('fromString returns custom for unknown', () {
      expect(SensorType.fromString('unknown'), SensorType.custom);
    });

    test('dbValue round-trips through fromString', () {
      for (final t in SensorType.values) {
        expect(SensorType.fromString(t.dbValue), t);
      }
    });

    test('all values have displayName', () {
      for (final t in SensorType.values) {
        expect(t.displayName.isNotEmpty, true);
      }
    });
  });

  group('SensorDefinition', () {
    final json = <String, dynamic>{
      'id': 's1',
      'device_id': 'd1',
      'project_id': 'p1',
      'name': 'Temp Sensor',
      'sensor_type': 'temperature',
      'telemetry_key': 'temperature',
      'unit': 'celsius',
      'min_value': -40,
      'max_value': 80,
      'sampling_interval_ms': 5000,
      'warning_threshold_low': 0.0,
      'warning_threshold_high': 45.0,
      'critical_threshold_low': -10.0,
      'critical_threshold_high': 60.0,
      'is_active': true,
      'metadata': <String, dynamic>{},
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-02T00:00:00Z',
    };

    test('fromJson parses correctly', () {
      final sensor = SensorDefinition.fromJson(json);
      expect(sensor.id, 's1');
      expect(sensor.name, 'Temp Sensor');
      expect(sensor.sensorType, SensorType.temperature);
      expect(sensor.telemetryKey, 'temperature');
      expect(sensor.unit, 'celsius');
      expect(sensor.samplingIntervalMs, 5000);
      expect(sensor.warningThresholdLow, 0.0);
      expect(sensor.warningThresholdHigh, 45.0);
      expect(sensor.criticalThresholdLow, -10.0);
      expect(sensor.criticalThresholdHigh, 60.0);
    });

    test('fromJson handles defaults for optional fields', () {
      final minimal = <String, dynamic>{
        'id': 's2',
        'device_id': 'd1',
        'project_id': 'p1',
        'name': 'Motion',
        'sensor_type': 'motion',
        'telemetry_key': 'motion',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };
      final sensor = SensorDefinition.fromJson(minimal);
      expect(sensor.unit, isNull);
      expect(sensor.minValue, isNull);
      expect(sensor.maxValue, isNull);
      expect(sensor.warningThresholdLow, isNull);
      expect(sensor.warningThresholdHigh, isNull);
      expect(sensor.criticalThresholdLow, isNull);
      expect(sensor.criticalThresholdHigh, isNull);
    });

    test('toJson produces expected keys', () {
      final sensor = SensorDefinition.fromJson(json);
      final output = sensor.toJson();
      expect(output['name'], 'Temp Sensor');
      expect(output['sensor_type'], 'temperature');
      expect(output['telemetry_key'], 'temperature');
      expect(output['unit'], 'celsius');
      expect(output.containsKey('id'), false);
    });
  });

  group('MqttConnectionStatus', () {
    test('enum has 4 states', () {
      expect(MqttConnectionStatus.values.length, 4);
    });

    test('all expected states exist', () {
      expect(
        MqttConnectionStatus.values,
        contains(MqttConnectionStatus.disconnected),
      );
      expect(
        MqttConnectionStatus.values,
        contains(MqttConnectionStatus.connecting),
      );
      expect(
        MqttConnectionStatus.values,
        contains(MqttConnectionStatus.connected),
      );
      expect(MqttConnectionStatus.values, contains(MqttConnectionStatus.error));
    });
  });

  group('HardwarePlatform', () {
    test('fromString parses all platforms', () {
      expect(HardwarePlatform.fromString('esp32'), HardwarePlatform.esp32);
      expect(HardwarePlatform.fromString('esp8266'), HardwarePlatform.esp8266);
      expect(
        HardwarePlatform.fromString('raspberryPi'),
        HardwarePlatform.raspberryPi,
      );
      expect(HardwarePlatform.fromString('arduino'), HardwarePlatform.arduino);
      expect(
        HardwarePlatform.fromString('genericMqtt'),
        HardwarePlatform.genericMqtt,
      );
    });

    test('fromString returns other for unknown', () {
      expect(
        HardwarePlatform.fromString('unknown_board'),
        HardwarePlatform.other,
      );
    });
  });

  group('Phase 5 Routes', () {
    test('pairDevice route name exists', () {
      expect(RouteNames.pairDevice, 'pairDevice');
    });

    test('manageSensors route name exists', () {
      expect(RouteNames.manageSensors, 'manageSensors');
    });

    test('manageActuators route name exists', () {
      expect(RouteNames.manageActuators, 'manageActuators');
    });
  });

  group('Device entity', () {
    test('isOnline defaults to false', () {
      final json = <String, dynamic>{
        'id': 'd1',
        'project_id': 'p1',
        'name': 'Test Device',
        'device_type': 'sensor_node',
        'hardware_platform': 'esp32',
        'is_active': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };
      final device = Device.fromJson(json);
      expect(device.isOnline, false);
      expect(device.lastSeenAt, isNull);
      expect(device.firmwareVersion, isNull);
    });

    test('fromJson parses online status', () {
      final json = <String, dynamic>{
        'id': 'd2',
        'project_id': 'p1',
        'name': 'Online Device',
        'device_type': 'actuator_node',
        'hardware_platform': 'esp8266',
        'is_active': true,
        'is_online': true,
        'firmware_version': '1.2.0',
        'last_seen_at': '2024-06-15T12:00:00Z',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };
      final device = Device.fromJson(json);
      expect(device.isOnline, true);
      expect(device.firmwareVersion, '1.2.0');
      expect(device.lastSeenAt, isNotNull);
    });
  });
}
