import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/core/constants/app_constants.dart';
import 'package:nexloza/core/utils/validators.dart';
import 'package:nexloza/shared/models/result.dart';
import 'package:nexloza/core/errors/failures.dart';
import 'package:nexloza/features/devices/domain/entities/device_entity.dart';
import 'package:nexloza/features/projects/domain/entities/project_entity.dart';

void main() {
  group('AppConstants', () {
    test('has correct app name', () {
      expect(AppConstants.appName, 'Nexloza');
    });

    test('has valid limits', () {
      expect(AppConstants.maxProjectsPerUser, greaterThan(0));
      expect(AppConstants.maxDevicesPerProject, greaterThan(0));
      expect(AppConstants.maxAutomationsPerProject, greaterThan(0));
    });

    test('has valid telemetry config', () {
      expect(AppConstants.telemetryRetentionDays, greaterThan(0));
      expect(AppConstants.heartbeatIntervalSeconds, greaterThan(0));
      expect(AppConstants.deviceOfflineThresholdSeconds, greaterThan(AppConstants.heartbeatIntervalSeconds));
    });
  });

  group('Validators', () {
    test('email validates correctly', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('invalid'), isNotNull);
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('user@domain.co.uk'), isNull);
    });

    test('password validates correctly', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('validpassword123'), isNull);
    });

    test('confirmPassword validates match', () {
      expect(Validators.confirmPassword('abc', 'def'), isNotNull);
      expect(Validators.confirmPassword('match', 'match'), isNull);
      expect(Validators.confirmPassword(null, 'test'), isNotNull);
    });

    test('required validates non-empty', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('  '), isNotNull);
      expect(Validators.required('value'), isNull);
    });

    test('numeric validates numbers', () {
      expect(Validators.numeric(null), isNotNull);
      expect(Validators.numeric('abc'), isNotNull);
      expect(Validators.numeric('42'), isNull);
      expect(Validators.numeric('3.14'), isNull);
    });
  });

  group('Result', () {
    test('Success returns data', () {
      final result = Result<int>.success(42);
      final value = result.when(
        success: (data) => data,
        failure: (f) => -1,
      );
      expect(value, 42);
    });

    test('Failure returns failure message', () {
      final result = Result<int>.failure(const ServerFailure('server error'));
      final value = result.when(
        success: (data) => '',
        failure: (f) => f.message,
      );
      expect(value, 'server error');
    });

    test('different failure types', () {
      expect(const ServerFailure('s').message, 's');
      expect(const CacheFailure('c').message, 'c');
      expect(const NetworkFailure('n').message, 'n');
      expect(const AuthFailure('a').message, 'a');
      expect(const ValidationFailure('v').message, 'v');
    });
  });

  group('HardwarePlatform', () {
    test('fromString parses correctly', () {
      expect(HardwarePlatform.fromString('esp32'), HardwarePlatform.esp32);
      expect(HardwarePlatform.fromString('esp8266'), HardwarePlatform.esp8266);
      expect(HardwarePlatform.fromString('unknown'), HardwarePlatform.other);
    });

    test('displayName is human-readable', () {
      expect(HardwarePlatform.esp32.displayName, 'ESP32');
      expect(HardwarePlatform.raspberryPi.displayName, 'Raspberry Pi');
    });
  });

  group('Project', () {
    test('fromJson parses correctly', () {
      final project = Project.fromJson({
        'id': 'test-id',
        'name': 'Test Project',
        'description': 'A test project',
        'category': 'Smart Home',
        'owner_id': 'user-123',
        'is_active': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      });
      expect(project.id, 'test-id');
      expect(project.name, 'Test Project');
      expect(project.category, 'Smart Home');
      expect(project.isActive, true);
    });

    test('categories list is not empty', () {
      expect(Project.categories, isNotEmpty);
      expect(Project.categories, contains('Smart Home'));
      expect(Project.categories, contains('Custom'));
    });
  });

  group('Device', () {
    test('fromJson parses correctly', () {
      final device = Device.fromJson({
        'id': 'device-1',
        'project_id': 'proj-1',
        'name': 'Living Room Light',
        'device_type': 'relay',
        'hardware_platform': 'esp32',
        'is_online': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      });
      expect(device.id, 'device-1');
      expect(device.name, 'Living Room Light');
      expect(device.hardwarePlatform, HardwarePlatform.esp32);
      expect(device.isOnline, true);
    });
  });
}
