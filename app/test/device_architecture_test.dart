import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/devices/domain/entities/device_entity.dart';
import 'package:nexloza/features/devices/domain/entities/sensor_entity.dart';
import 'package:nexloza/features/devices/domain/entities/actuator_entity.dart';
import 'package:nexloza/features/devices/domain/entities/telemetry_entity.dart';
import 'package:nexloza/features/devices/domain/entities/device_command_entity.dart';
import 'package:nexloza/features/devices/domain/entities/device_credential_entity.dart';
import 'package:nexloza/routing/route_names.dart';

void main() {
  // ─── Device Entity ─────────────────────────────────────────

  group('Device', () {
    final json = {
      'id': 'dev-1',
      'project_id': 'proj-1',
      'name': 'Test Device',
      'device_type': 'relay',
      'hardware_platform': 'esp32',
      'firmware_version': '1.2.0',
      'mac_address': 'AA:BB:CC:DD:EE:FF',
      'is_online': true,
      'last_seen_at': '2026-11-01T12:00:00Z',
      'metadata': <String, dynamic>{'location': 'lab'},
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };

    test('fromJson creates correct instance', () {
      final device = Device.fromJson(json);
      expect(device.id, 'dev-1');
      expect(device.projectId, 'proj-1');
      expect(device.name, 'Test Device');
      expect(device.deviceType, 'relay');
      expect(device.hardwarePlatform, HardwarePlatform.esp32);
      expect(device.firmwareVersion, '1.2.0');
      expect(device.macAddress, 'AA:BB:CC:DD:EE:FF');
      expect(device.isOnline, true);
      expect(device.lastSeenAt, isNotNull);
      expect(device.metadata['location'], 'lab');
    });

    test('toJson serializes correctly', () {
      final device = Device.fromJson(json);
      final serialized = device.toJson();
      expect(serialized['name'], 'Test Device');
      expect(serialized['device_type'], 'relay');
      expect(serialized['hardware_platform'], 'esp32');
      expect(serialized['firmware_version'], '1.2.0');
      expect(serialized.containsKey('id'), false);
    });

    test('handles minimal JSON with defaults', () {
      final minimal = {
        'id': 'dev-2',
        'project_id': 'proj-1',
        'name': 'Minimal',
        'device_type': 'sensor',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final device = Device.fromJson(minimal);
      expect(device.hardwarePlatform, HardwarePlatform.esp32);
      expect(device.isOnline, false);
      expect(device.firmwareVersion, isNull);
      expect(device.macAddress, isNull);
      expect(device.lastSeenAt, isNull);
      expect(device.metadata, isEmpty);
    });

    test('fromJson/toJson roundtrip preserves data', () {
      final device = Device.fromJson(json);
      final reJson = device.toJson();
      reJson['id'] = 'dev-1';
      reJson['is_online'] = true;
      reJson['last_seen_at'] = '2026-11-01T12:00:00.000Z';
      reJson['created_at'] = '2026-01-01T00:00:00.000Z';
      reJson['updated_at'] = '2026-01-01T00:00:00.000Z';
      final device2 = Device.fromJson(reJson);
      expect(device2.name, device.name);
      expect(device2.deviceType, device.deviceType);
    });
  });

  // ─── HardwarePlatform ──────────────────────────────────────

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

    test('fromString defaults to other for unknown', () {
      expect(HardwarePlatform.fromString('unknown'), HardwarePlatform.other);
      expect(HardwarePlatform.fromString(''), HardwarePlatform.other);
    });

    test('displayName returns readable names', () {
      expect(HardwarePlatform.esp32.displayName, 'ESP32');
      expect(HardwarePlatform.esp8266.displayName, 'ESP8266');
      expect(HardwarePlatform.raspberryPi.displayName, 'Raspberry Pi');
      expect(HardwarePlatform.arduino.displayName, 'Arduino');
      expect(HardwarePlatform.genericMqtt.displayName, 'Generic MQTT');
      expect(HardwarePlatform.other.displayName, 'Other');
    });
  });

  // ─── Sensor Entity ─────────────────────────────────────────

  group('SensorType', () {
    test('fromString parses snake_case database values', () {
      expect(SensorType.fromString('temperature'), SensorType.temperature);
      expect(SensorType.fromString('water_level'), SensorType.waterLevel);
      expect(SensorType.fromString('soil_moisture'), SensorType.soilMoisture);
      expect(SensorType.fromString('air_quality'), SensorType.airQuality);
      expect(SensorType.fromString('flow_rate'), SensorType.flowRate);
    });

    test('fromString defaults to custom for unknown', () {
      expect(SensorType.fromString('unknown'), SensorType.custom);
    });

    test('dbValue returns correct snake_case', () {
      expect(SensorType.waterLevel.dbValue, 'water_level');
      expect(SensorType.soilMoisture.dbValue, 'soil_moisture');
      expect(SensorType.airQuality.dbValue, 'air_quality');
      expect(SensorType.flowRate.dbValue, 'flow_rate');
      expect(SensorType.temperature.dbValue, 'temperature');
      expect(SensorType.humidity.dbValue, 'humidity');
    });

    test('displayName returns readable names', () {
      expect(SensorType.temperature.displayName, 'Temperature');
      expect(SensorType.waterLevel.displayName, 'Water Level');
      expect(SensorType.soilMoisture.displayName, 'Soil Moisture');
      expect(SensorType.airQuality.displayName, 'Air Quality');
      expect(SensorType.ph.displayName, 'pH');
      expect(SensorType.uv.displayName, 'UV');
      expect(SensorType.gps.displayName, 'GPS');
    });

    test('all 24 sensor types are defined', () {
      expect(SensorType.values.length, 24);
    });
  });

  group('SensorDefinition', () {
    final json = {
      'id': 'sen-1',
      'device_id': 'dev-1',
      'project_id': 'proj-1',
      'name': 'Room Temperature',
      'sensor_type': 'temperature',
      'unit': '°C',
      'telemetry_key': 'temp_1',
      'sampling_interval_ms': 30000,
      'calibration': <String, dynamic>{'offset': 0.5},
      'min_value': -40.0,
      'max_value': 85.0,
      'warning_threshold_low': 0.0,
      'warning_threshold_high': 50.0,
      'critical_threshold_low': -10.0,
      'critical_threshold_high': 70.0,
      'is_active': true,
      'metadata': <String, dynamic>{},
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };

    test('fromJson creates correct instance', () {
      final sensor = SensorDefinition.fromJson(json);
      expect(sensor.id, 'sen-1');
      expect(sensor.deviceId, 'dev-1');
      expect(sensor.name, 'Room Temperature');
      expect(sensor.sensorType, SensorType.temperature);
      expect(sensor.unit, '°C');
      expect(sensor.telemetryKey, 'temp_1');
      expect(sensor.samplingIntervalMs, 30000);
      expect(sensor.calibration['offset'], 0.5);
      expect(sensor.minValue, -40.0);
      expect(sensor.maxValue, 85.0);
      expect(sensor.warningThresholdLow, 0.0);
      expect(sensor.warningThresholdHigh, 50.0);
      expect(sensor.criticalThresholdLow, -10.0);
      expect(sensor.criticalThresholdHigh, 70.0);
      expect(sensor.isActive, true);
    });

    test('toJson serializes correctly', () {
      final sensor = SensorDefinition.fromJson(json);
      final serialized = sensor.toJson();
      expect(serialized['sensor_type'], 'temperature');
      expect(serialized['telemetry_key'], 'temp_1');
      expect(serialized['unit'], '°C');
      expect(serialized['sampling_interval_ms'], 30000);
      expect(serialized.containsKey('id'), false);
    });

    test('handles minimal JSON with defaults', () {
      final minimal = {
        'id': 'sen-2',
        'device_id': 'dev-1',
        'project_id': 'proj-1',
        'name': 'Minimal Sensor',
        'sensor_type': 'humidity',
        'telemetry_key': 'hum_1',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final sensor = SensorDefinition.fromJson(minimal);
      expect(sensor.unit, isNull);
      expect(sensor.samplingIntervalMs, 60000);
      expect(sensor.calibration, isEmpty);
      expect(sensor.minValue, isNull);
      expect(sensor.warningThresholdHigh, isNull);
      expect(sensor.isActive, true);
    });
  });

  // ─── Actuator Entity ───────────────────────────────────────

  group('ActuatorType', () {
    test('fromString parses all types including snake_case', () {
      expect(ActuatorType.fromString('relay'), ActuatorType.relay);
      expect(ActuatorType.fromString('switch'), ActuatorType.switchType);
      expect(ActuatorType.fromString('smart_plug'), ActuatorType.smartPlug);
      expect(ActuatorType.fromString('rgb_led'), ActuatorType.rgbLed);
    });

    test('fromString defaults to custom for unknown', () {
      expect(ActuatorType.fromString('unknown'), ActuatorType.custom);
    });

    test('dbValue returns correct snake_case', () {
      expect(ActuatorType.switchType.dbValue, 'switch');
      expect(ActuatorType.smartPlug.dbValue, 'smart_plug');
      expect(ActuatorType.rgbLed.dbValue, 'rgb_led');
      expect(ActuatorType.relay.dbValue, 'relay');
    });

    test('displayName returns readable names', () {
      expect(ActuatorType.relay.displayName, 'Relay');
      expect(ActuatorType.switchType.displayName, 'Switch');
      expect(ActuatorType.smartPlug.displayName, 'Smart Plug');
      expect(ActuatorType.rgbLed.displayName, 'RGB LED');
    });

    test('all 16 actuator types are defined', () {
      expect(ActuatorType.values.length, 16);
    });
  });

  group('ControlType', () {
    test('fromString parses all types', () {
      expect(ControlType.fromString('toggle'), ControlType.toggle);
      expect(ControlType.fromString('slider'), ControlType.slider);
      expect(ControlType.fromString('numeric'), ControlType.numeric);
      expect(ControlType.fromString('multi_level'), ControlType.multiLevel);
      expect(ControlType.fromString('color'), ControlType.color);
      expect(ControlType.fromString('custom'), ControlType.custom);
    });

    test('fromString defaults to toggle for unknown', () {
      expect(ControlType.fromString('unknown'), ControlType.toggle);
    });

    test('dbValue returns correct snake_case', () {
      expect(ControlType.multiLevel.dbValue, 'multi_level');
      expect(ControlType.toggle.dbValue, 'toggle');
      expect(ControlType.slider.dbValue, 'slider');
    });

    test('displayName returns readable names', () {
      expect(ControlType.toggle.displayName, 'Toggle');
      expect(ControlType.slider.displayName, 'Slider');
      expect(ControlType.multiLevel.displayName, 'Multi Level');
      expect(ControlType.color.displayName, 'Color');
    });

    test('all 6 control types are defined', () {
      expect(ControlType.values.length, 6);
    });
  });

  group('ActuatorDefinition', () {
    final json = {
      'id': 'act-1',
      'device_id': 'dev-1',
      'project_id': 'proj-1',
      'name': 'Main Relay',
      'actuator_type': 'relay',
      'control_type': 'toggle',
      'telemetry_key': 'relay_state',
      'command_key': 'relay_1',
      'min_value': 0,
      'max_value': 1,
      'step': 1,
      'current_state': <String, dynamic>{'is_on': true, 'value': 1.0},
      'safety_limits': <String, dynamic>{'max_on_duration_s': 3600},
      'is_active': true,
      'metadata': <String, dynamic>{},
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };

    test('fromJson creates correct instance', () {
      final actuator = ActuatorDefinition.fromJson(json);
      expect(actuator.id, 'act-1');
      expect(actuator.name, 'Main Relay');
      expect(actuator.actuatorType, ActuatorType.relay);
      expect(actuator.controlType, ControlType.toggle);
      expect(actuator.commandKey, 'relay_1');
      expect(actuator.minValue, 0);
      expect(actuator.maxValue, 1);
    });

    test('isOn reads from currentState', () {
      final actuator = ActuatorDefinition.fromJson(json);
      expect(actuator.isOn, true);
    });

    test('isOn defaults to false when not set', () {
      final offJson = {...json, 'current_state': <String, dynamic>{}};
      final actuator = ActuatorDefinition.fromJson(offJson);
      expect(actuator.isOn, false);
    });

    test('currentValue reads from currentState', () {
      final actuator = ActuatorDefinition.fromJson(json);
      expect(actuator.currentValue, 1.0);
    });

    test('currentValue defaults to 0 when not set', () {
      final noState = {...json, 'current_state': <String, dynamic>{}};
      final actuator = ActuatorDefinition.fromJson(noState);
      expect(actuator.currentValue, 0);
    });

    test('toJson serializes correctly', () {
      final actuator = ActuatorDefinition.fromJson(json);
      final serialized = actuator.toJson();
      expect(serialized['actuator_type'], 'relay');
      expect(serialized['control_type'], 'toggle');
      expect(serialized['command_key'], 'relay_1');
      expect(serialized.containsKey('id'), false);
    });
  });

  // ─── Telemetry Entity ──────────────────────────────────────

  group('TelemetryReading', () {
    test('fromJson with numeric value', () {
      final reading = TelemetryReading.fromJson({
        'id': 1,
        'device_id': 'dev-1',
        'sensor_key': 'temp_1',
        'value_numeric': 23.5,
        'value_text': null,
        'value_json': null,
        'recorded_at': '2026-01-01T12:00:00Z',
        'received_at': '2026-01-01T12:00:00Z',
      });
      expect(reading.sensorKey, 'temp_1');
      expect(reading.valueNumeric, 23.5);
      expect(reading.displayValue, '23.5');
    });

    test('fromJson with text value', () {
      final reading = TelemetryReading.fromJson({
        'id': 2,
        'device_id': 'dev-1',
        'sensor_key': 'status',
        'value_numeric': null,
        'value_text': 'OK',
        'value_json': null,
        'recorded_at': '2026-01-01T12:00:00Z',
        'received_at': '2026-01-01T12:00:00Z',
      });
      expect(reading.valueText, 'OK');
      expect(reading.displayValue, 'OK');
    });

    test('fromJson with json value', () {
      final reading = TelemetryReading.fromJson({
        'id': 3,
        'device_id': 'dev-1',
        'sensor_key': 'gps',
        'value_numeric': null,
        'value_text': null,
        'value_json': <String, dynamic>{'lat': 40.7, 'lng': -74.0},
        'recorded_at': '2026-01-01T12:00:00Z',
        'received_at': '2026-01-01T12:00:00Z',
      });
      expect(reading.valueJson, isNotNull);
      expect(reading.valueJson!['lat'], 40.7);
    });

    test('displayValue prefers numeric > text > json > --', () {
      final noValue = TelemetryReading.fromJson({
        'id': 4,
        'device_id': 'dev-1',
        'sensor_key': 'empty',
        'value_numeric': null,
        'value_text': null,
        'value_json': null,
        'recorded_at': '2026-01-01T12:00:00Z',
        'received_at': '2026-01-01T12:00:00Z',
      });
      expect(noValue.displayValue, '--');
    });

    test('numeric displayValue formats integers without decimals', () {
      final reading = TelemetryReading.fromJson({
        'id': 5,
        'device_id': 'dev-1',
        'sensor_key': 'count',
        'value_numeric': 42.0,
        'value_text': null,
        'value_json': null,
        'recorded_at': '2026-01-01T12:00:00Z',
        'received_at': '2026-01-01T12:00:00Z',
      });
      expect(reading.displayValue, '42');
    });
  });

  // ─── Command Entity ────────────────────────────────────────

  group('CommandStatus', () {
    test('fromString parses all statuses', () {
      expect(CommandStatus.fromString('pending'), CommandStatus.pending);
      expect(CommandStatus.fromString('sent'), CommandStatus.sent);
      expect(
        CommandStatus.fromString('acknowledged'),
        CommandStatus.acknowledged,
      );
      expect(CommandStatus.fromString('executed'), CommandStatus.executed);
      expect(CommandStatus.fromString('failed'), CommandStatus.failed);
      expect(CommandStatus.fromString('timeout'), CommandStatus.timeout);
    });

    test('fromString defaults to pending for unknown', () {
      expect(CommandStatus.fromString('bogus'), CommandStatus.pending);
    });

    test('isTerminal is true for executed, failed, timeout', () {
      expect(CommandStatus.executed.isTerminal, true);
      expect(CommandStatus.failed.isTerminal, true);
      expect(CommandStatus.timeout.isTerminal, true);
      expect(CommandStatus.pending.isTerminal, false);
      expect(CommandStatus.sent.isTerminal, false);
      expect(CommandStatus.acknowledged.isTerminal, false);
    });

    test('displayName returns readable names', () {
      expect(CommandStatus.pending.displayName, 'Pending');
      expect(CommandStatus.sent.displayName, 'Sent');
      expect(CommandStatus.acknowledged.displayName, 'Acknowledged');
      expect(CommandStatus.executed.displayName, 'Executed');
      expect(CommandStatus.failed.displayName, 'Failed');
      expect(CommandStatus.timeout.displayName, 'Timeout');
    });
  });

  group('DeviceCommand', () {
    final json = {
      'id': 'cmd-1',
      'device_id': 'dev-1',
      'command_type': 'relay',
      'payload': <String, dynamic>{'value': true},
      'status': 'pending',
      'sent_at': null,
      'acknowledged_at': null,
      'executed_at': null,
      'error_message': null,
      'expires_at': DateTime.now()
          .add(const Duration(seconds: 30))
          .toIso8601String(),
      'created_at': '2026-01-01T12:00:00Z',
      'updated_at': '2026-01-01T12:00:00Z',
    };

    test('fromJson creates correct instance', () {
      final command = DeviceCommand.fromJson(json);
      expect(command.id, 'cmd-1');
      expect(command.deviceId, 'dev-1');
      expect(command.commandType, 'relay');
      expect(command.payload['value'], true);
      expect(command.status, CommandStatus.pending);
      expect(command.sentAt, isNull);
      expect(command.acknowledgedAt, isNull);
      expect(command.executedAt, isNull);
    });

    test('isExpired returns false for future expiry', () {
      final command = DeviceCommand.fromJson(json);
      expect(command.isExpired, false);
    });

    test('isExpired returns true for past expiry', () {
      final expiredJson = {
        ...json,
        'expires_at': DateTime.now()
            .subtract(const Duration(seconds: 30))
            .toIso8601String(),
      };
      final command = DeviceCommand.fromJson(expiredJson);
      expect(command.isExpired, true);
    });

    test('isExpired returns false when no expiry set', () {
      final noExpiryJson = {...json, 'expires_at': null};
      final command = DeviceCommand.fromJson(noExpiryJson);
      expect(command.isExpired, false);
    });

    test('fromJson with full lifecycle timestamps', () {
      final fullJson = {
        ...json,
        'status': 'executed',
        'sent_at': '2026-01-01T12:00:01Z',
        'acknowledged_at': '2026-01-01T12:00:02Z',
        'executed_at': '2026-01-01T12:00:03Z',
      };
      final command = DeviceCommand.fromJson(fullJson);
      expect(command.status, CommandStatus.executed);
      expect(command.sentAt, isNotNull);
      expect(command.acknowledgedAt, isNotNull);
      expect(command.executedAt, isNotNull);
    });

    test('fromJson with error message', () {
      final failedJson = {
        ...json,
        'status': 'failed',
        'error_message': 'Device unreachable',
      };
      final command = DeviceCommand.fromJson(failedJson);
      expect(command.status, CommandStatus.failed);
      expect(command.errorMessage, 'Device unreachable');
    });
  });

  // ─── Credential Entity ─────────────────────────────────────

  group('DeviceCredential', () {
    test('fromJson creates correct instance', () {
      final cred = DeviceCredential.fromJson({
        'id': 'cred-1',
        'device_id': 'dev-1',
        'api_key': 'nxl_abc123',
        'is_active': true,
        'last_used_at': '2026-01-01T12:00:00Z',
        'expires_at': null,
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(cred.id, 'cred-1');
      expect(cred.apiKey, 'nxl_abc123');
      expect(cred.isActive, true);
      expect(cred.lastUsedAt, isNotNull);
      expect(cred.expiresAt, isNull);
    });
  });

  group('ProvisionedCredential', () {
    test('holds apiKey and apiSecret', () {
      final cred = DeviceCredential.fromJson({
        'id': 'cred-1',
        'device_id': 'dev-1',
        'api_key': 'nxl_key123',
        'is_active': true,
        'created_at': '2026-01-01T00:00:00Z',
      });
      final provisioned = ProvisionedCredential(
        apiKey: 'nxl_key123',
        apiSecret: 'secret456',
        credential: cred,
      );
      expect(provisioned.apiKey, 'nxl_key123');
      expect(provisioned.apiSecret, 'secret456');
      expect(provisioned.credential.id, 'cred-1');
    });
  });

  // ─── Route Names ───────────────────────────────────────────

  group('RouteNames Device Architecture', () {
    test('has all device routes', () {
      expect(RouteNames.devices, 'devices');
      expect(RouteNames.deviceDetail, 'deviceDetail');
      expect(RouteNames.addDevice, 'addDevice');
      expect(RouteNames.editDevice, 'editDevice');
      expect(RouteNames.manageSensors, 'manageSensors');
      expect(RouteNames.manageActuators, 'manageActuators');
    });
  });

  // ─── Cross-entity Integration ──────────────────────────────

  group('Cross-entity integration', () {
    test('sensor telemetryKey matches telemetry sensorKey pattern', () {
      final sensor = SensorDefinition.fromJson({
        'id': 'sen-1',
        'device_id': 'dev-1',
        'project_id': 'proj-1',
        'name': 'Temp',
        'sensor_type': 'temperature',
        'telemetry_key': 'temp_1',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });
      final reading = TelemetryReading.fromJson({
        'id': 1,
        'device_id': 'dev-1',
        'sensor_key': 'temp_1',
        'value_numeric': 25.0,
        'recorded_at': '2026-01-01T12:00:00Z',
        'received_at': '2026-01-01T12:00:00Z',
      });
      expect(sensor.telemetryKey, reading.sensorKey);
    });

    test('actuator commandKey matches command commandType pattern', () {
      final actuator = ActuatorDefinition.fromJson({
        'id': 'act-1',
        'device_id': 'dev-1',
        'project_id': 'proj-1',
        'name': 'Relay',
        'actuator_type': 'relay',
        'control_type': 'toggle',
        'command_key': 'relay_1',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });
      final command = DeviceCommand.fromJson({
        'id': 'cmd-1',
        'device_id': 'dev-1',
        'command_type': 'relay_1',
        'payload': <String, dynamic>{'value': true},
        'status': 'pending',
        'created_at': '2026-01-01T12:00:00Z',
        'updated_at': '2026-01-01T12:00:00Z',
      });
      expect(actuator.commandKey, command.commandType);
    });

    test('command lifecycle follows correct order', () {
      final statuses = [
        CommandStatus.pending,
        CommandStatus.sent,
        CommandStatus.acknowledged,
        CommandStatus.executed,
      ];
      for (var i = 0; i < statuses.length - 1; i++) {
        expect(
          statuses[i].isTerminal,
          false,
          reason: '${statuses[i]} should not be terminal',
        );
      }
      expect(statuses.last.isTerminal, true);
    });

    test('all hardware platforms have displayName', () {
      for (final platform in HardwarePlatform.values) {
        expect(
          platform.displayName.isNotEmpty,
          true,
          reason: '${platform.name} missing displayName',
        );
      }
    });

    test('all sensor types roundtrip through dbValue/fromString', () {
      for (final type in SensorType.values) {
        final roundtripped = SensorType.fromString(type.dbValue);
        expect(
          roundtripped,
          type,
          reason: '${type.name} failed dbValue roundtrip',
        );
      }
    });

    test('all actuator types roundtrip through dbValue/fromString', () {
      for (final type in ActuatorType.values) {
        final roundtripped = ActuatorType.fromString(type.dbValue);
        expect(
          roundtripped,
          type,
          reason: '${type.name} failed dbValue roundtrip',
        );
      }
    });

    test('all control types roundtrip through dbValue/fromString', () {
      for (final type in ControlType.values) {
        final roundtripped = ControlType.fromString(type.dbValue);
        expect(
          roundtripped,
          type,
          reason: '${type.name} failed dbValue roundtrip',
        );
      }
    });
  });
}
