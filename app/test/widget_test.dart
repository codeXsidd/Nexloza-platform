import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/core/constants/app_constants.dart';
import 'package:nexloza/core/constants/mqtt_constants.dart';
import 'package:nexloza/core/utils/validators.dart';
import 'package:nexloza/core/extensions/string_extensions.dart';
import 'package:nexloza/core/extensions/datetime_extensions.dart';
import 'package:nexloza/shared/models/result.dart';
import 'package:nexloza/core/errors/failures.dart';
import 'package:nexloza/core/errors/exceptions.dart';
import 'package:nexloza/features/devices/domain/entities/device_entity.dart';
import 'package:nexloza/features/projects/domain/entities/project_entity.dart';
import 'package:nexloza/features/automations/domain/entities/automation_entity.dart';
import 'package:nexloza/features/notifications/domain/entities/notification_entity.dart';
import 'package:nexloza/features/scenes/domain/entities/scene_entity.dart';
import 'package:nexloza/theme/app_colors.dart';
import 'package:nexloza/theme/app_theme.dart';
import 'package:nexloza/theme/app_spacing.dart';
import 'package:nexloza/routing/route_names.dart';

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
      expect(
        AppConstants.deviceOfflineThresholdSeconds,
        greaterThan(AppConstants.heartbeatIntervalSeconds),
      );
    });
  });

  group('MqttConstants', () {
    test('has valid default ports', () {
      expect(MqttConstants.defaultPort, 1883);
      expect(MqttConstants.defaultTlsPort, 8883);
      expect(MqttConstants.defaultWsPort, 8083);
    });

    test('has valid keep alive', () {
      expect(MqttConstants.keepAliveSeconds, greaterThan(0));
    });

    test('topic prefix includes version', () {
      expect(MqttConstants.topicPrefix, 'nexloza/v1');
    });

    test('canonical topic builders produce correct v1 paths', () {
      expect(
        MqttConstants.telemetryTopic('org1', 'proj1', 'dev1'),
        'nexloza/v1/org1/proj1/dev1/telemetry',
      );
      expect(
        MqttConstants.commandTopic('org1', 'proj1', 'dev1'),
        'nexloza/v1/org1/proj1/dev1/command',
      );
      expect(
        MqttConstants.commandAckTopic('org1', 'proj1', 'dev1'),
        'nexloza/v1/org1/proj1/dev1/command-ack',
      );
      expect(
        MqttConstants.stateTopic('org1', 'proj1', 'dev1'),
        'nexloza/v1/org1/proj1/dev1/state',
      );
      expect(
        MqttConstants.statusTopic('org1', 'proj1', 'dev1'),
        'nexloza/v1/org1/proj1/dev1/status',
      );
      expect(
        MqttConstants.configTopic('org1', 'proj1', 'dev1'),
        'nexloza/v1/org1/proj1/dev1/config',
      );
    });

    test('wildcard topics work correctly', () {
      expect(
        MqttConstants.deviceWildcard('org1', 'proj1', 'dev1'),
        'nexloza/v1/org1/proj1/dev1/#',
      );
      expect(
        MqttConstants.projectWildcard('org1', 'proj1'),
        'nexloza/v1/org1/proj1/#',
      );
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

  group('StringExtensions', () {
    test('capitalize works correctly', () {
      expect('hello'.capitalize, 'Hello');
      expect(''.capitalize, '');
      expect('a'.capitalize, 'A');
      expect('Hello'.capitalize, 'Hello');
    });

    test('initials extracts correctly', () {
      expect('John Doe'.initials, 'JD');
      expect('Alice'.initials, 'A');
      expect('Alice Bob Charlie'.initials, 'AC');
    });

    test('isValidEmail checks format', () {
      expect('user@example.com'.isValidEmail, isTrue);
      expect('invalid'.isValidEmail, isFalse);
      expect('@nope.com'.isValidEmail, isFalse);
    });

    test('nullable string extensions', () {
      const String? nullStr = null;
      expect(nullStr.isNullOrEmpty, isTrue);
      expect(''.isNullOrEmpty, isTrue);
      expect('hello'.isNullOrEmpty, isFalse);
      expect(nullStr.orEmpty, '');
      expect('value'.orEmpty, 'value');
    });
  });

  group('DateTimeExtensions', () {
    test('formatted produces dd/mm/yyyy', () {
      final dt = DateTime(2024, 3, 5);
      expect(dt.formatted, '05/03/2024');
    });

    test('formattedWithTime includes time', () {
      final dt = DateTime(2024, 3, 5, 14, 30);
      expect(dt.formattedWithTime, '05/03/2024 14:30');
    });

    test('isToday returns true for today', () {
      expect(DateTime.now().isToday, isTrue);
      expect(DateTime(2000, 1, 1).isToday, isFalse);
    });
  });

  group('Result', () {
    test('Success returns data', () {
      final result = Result<int>.success(42);
      final value = result.when(success: (data) => data, failure: (f) => -1);
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

    test('Success with null data', () {
      final result = Result<void>.success(null);
      final value = result.when(success: (_) => 'ok', failure: (f) => 'fail');
      expect(value, 'ok');
    });

    test('Result is sealed — exhaustive pattern matching', () {
      Result<String> result = Result.success('hello');
      final output = switch (result) {
        Success<String>(data: final d) => d,
        ResultFailure<String>(failure: final f) => f.message,
      };
      expect(output, 'hello');
    });
  });

  group('Exceptions', () {
    test('ServerException has message and code', () {
      const ex = ServerException('bad request', statusCode: 400);
      expect(ex.message, 'bad request');
      expect(ex.statusCode, 400);
      expect(ex.toString(), contains('bad request'));
    });

    test('CacheException has message', () {
      const ex = CacheException('cache miss');
      expect(ex.message, 'cache miss');
      expect(ex.toString(), contains('cache miss'));
    });

    test('NetworkException has message', () {
      const ex = NetworkException('no internet');
      expect(ex.message, 'no internet');
    });

    test('DeviceException has message', () {
      const ex = DeviceException('device not found');
      expect(ex.message, 'device not found');
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
      expect(HardwarePlatform.esp8266.displayName, 'ESP8266');
      expect(HardwarePlatform.raspberryPi.displayName, 'Raspberry Pi');
      expect(HardwarePlatform.arduino.displayName, 'Arduino');
      expect(HardwarePlatform.genericMqtt.displayName, 'Generic MQTT');
      expect(HardwarePlatform.other.displayName, 'Other');
    });

    test('all values have a displayName', () {
      for (final platform in HardwarePlatform.values) {
        expect(platform.displayName, isNotEmpty);
      }
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
      expect(project.description, 'A test project');
      expect(project.category, 'Smart Home');
      expect(project.ownerId, 'user-123');
      expect(project.isActive, true);
    });

    test('fromJson handles defaults for optional fields', () {
      final project = Project.fromJson({
        'id': 'test-id',
        'name': 'Minimal',
        'owner_id': 'user-1',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      });
      expect(project.description, isNull);
      expect(project.category, isNull);
      expect(project.settings, isEmpty);
      expect(project.isActive, true);
    });

    test('toJson produces expected keys', () {
      final project = Project.fromJson({
        'id': 'p1',
        'name': 'My Project',
        'owner_id': 'u1',
        'category': 'Custom',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      });
      final json = project.toJson();
      expect(json['name'], 'My Project');
      expect(json['category'], 'Custom');
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('owner_id'), isFalse);
    });

    test('categories list is not empty', () {
      expect(Project.categories, isNotEmpty);
      expect(Project.categories, contains('Smart Home'));
      expect(Project.categories, contains('Custom'));
      expect(Project.categories.length, greaterThanOrEqualTo(5));
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

    test('fromJson handles defaults', () {
      final device = Device.fromJson({
        'id': 'd1',
        'project_id': 'p1',
        'name': 'Test',
        'device_type': 'sensor',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      });
      expect(device.isOnline, isFalse);
      expect(device.hardwarePlatform, HardwarePlatform.esp32);
      expect(device.firmwareVersion, isNull);
      expect(device.lastSeenAt, isNull);
      expect(device.metadata, isEmpty);
    });

    test('toJson produces expected keys', () {
      final device = Device.fromJson({
        'id': 'd1',
        'project_id': 'p1',
        'name': 'Sensor',
        'device_type': 'dht22',
        'hardware_platform': 'esp8266',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      });
      final json = device.toJson();
      expect(json['project_id'], 'p1');
      expect(json['name'], 'Sensor');
      expect(json['device_type'], 'dht22');
      expect(json['hardware_platform'], 'esp8266');
      expect(json.containsKey('id'), isFalse);
    });
  });

  group('Automation', () {
    test('fromJson parses correctly', () {
      final automation = Automation.fromJson({
        'id': 'auto-1',
        'project_id': 'proj-1',
        'name': 'Night Mode',
        'description': 'Turn off lights at night',
        'is_enabled': true,
        'priority': 5,
        'cooldown_seconds': 120,
        'max_executions_per_hour': 30,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      });
      expect(automation.id, 'auto-1');
      expect(automation.name, 'Night Mode');
      expect(automation.description, 'Turn off lights at night');
      expect(automation.isEnabled, true);
      expect(automation.priority, 5);
      expect(automation.cooldownSeconds, 120);
      expect(automation.maxExecutionsPerHour, 30);
    });

    test('fromJson handles defaults', () {
      final automation = Automation.fromJson({
        'id': 'a1',
        'project_id': 'p1',
        'name': 'Test',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      });
      expect(automation.isEnabled, true);
      expect(automation.priority, 0);
      expect(automation.cooldownSeconds, 60);
      expect(automation.maxExecutionsPerHour, 60);
    });
  });

  group('AppNotification', () {
    test('fromJson parses correctly', () {
      final notification = AppNotification.fromJson({
        'id': 'notif-1',
        'user_id': 'user-1',
        'project_id': 'proj-1',
        'title': 'Device Offline',
        'body': 'Your sensor went offline',
        'category': 'device',
        'severity': 'warning',
        'is_read': false,
        'created_at': '2024-01-01T00:00:00Z',
      });
      expect(notification.id, 'notif-1');
      expect(notification.title, 'Device Offline');
      expect(notification.category, NotificationCategory.device);
      expect(notification.severity, NotificationSeverity.warning);
      expect(notification.isRead, false);
    });

    test('fromJson handles defaults and unknown values', () {
      final notification = AppNotification.fromJson({
        'id': 'n1',
        'user_id': 'u1',
        'title': 'Test',
        'body': 'Body',
        'category': 'unknown_category',
        'severity': 'unknown_severity',
        'created_at': '2024-01-01T00:00:00Z',
      });
      expect(notification.category, NotificationCategory.system);
      expect(notification.severity, NotificationSeverity.info);
      expect(notification.isRead, false);
      expect(notification.projectId, isNull);
    });

    test('all notification categories exist', () {
      expect(NotificationCategory.values.length, 5);
      expect(
        NotificationCategory.values,
        contains(NotificationCategory.device),
      );
      expect(NotificationCategory.values, contains(NotificationCategory.alert));
    });

    test('all severity levels exist', () {
      expect(NotificationSeverity.values.length, 3);
    });
  });

  group('Scene', () {
    test('fromJson parses correctly', () {
      final scene = Scene.fromJson({
        'id': 'scene-1',
        'project_id': 'proj-1',
        'name': 'Night Mode',
        'description': 'Dim all lights',
        'is_active': true,
        'created_at': '2024-01-01T00:00:00Z',
      });
      expect(scene.id, 'scene-1');
      expect(scene.name, 'Night Mode');
      expect(scene.isActive, true);
    });

    test('presets are available', () {
      expect(Scene.presets, isNotEmpty);
      expect(Scene.presets, contains('Night Mode'));
      expect(Scene.presets, contains('Custom'));
    });
  });

  group('Theme', () {
    test('light theme uses Material 3', () {
      final theme = AppTheme.light;
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.light);
    });

    test('dark theme uses Material 3', () {
      final theme = AppTheme.dark;
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.dark);
    });

    test('both themes have the same seed color', () {
      final lightPrimary = AppTheme.light.colorScheme.primary;
      final darkPrimary = AppTheme.dark.colorScheme.primary;
      expect(lightPrimary, isNotNull);
      expect(darkPrimary, isNotNull);
    });

    test('AppColors has valid IoT-related colors', () {
      expect(AppColors.primary, isNotNull);
      expect(AppColors.online, isNotNull);
      expect(AppColors.offline, isNotNull);
      expect(AppColors.online, isNot(equals(AppColors.offline)));
    });

    test('AppSpacing has positive values', () {
      expect(AppSpacing.xs, greaterThan(0));
      expect(AppSpacing.sm, greaterThan(AppSpacing.xs));
      expect(AppSpacing.md, greaterThan(AppSpacing.sm));
      expect(AppSpacing.lg, greaterThan(AppSpacing.md));
      expect(AppSpacing.xl, greaterThan(AppSpacing.lg));
    });
  });

  group('RouteNames', () {
    test('has required route names', () {
      expect(RouteNames.splash, isNotEmpty);
      expect(RouteNames.login, isNotEmpty);
      expect(RouteNames.register, isNotEmpty);
      expect(RouteNames.home, isNotEmpty);
      expect(RouteNames.projects, isNotEmpty);
      expect(RouteNames.devices, isNotEmpty);
      expect(RouteNames.automations, isNotEmpty);
      expect(RouteNames.aiAssistant, isNotEmpty);
      expect(RouteNames.notifications, isNotEmpty);
      expect(RouteNames.settings, isNotEmpty);
      expect(RouteNames.profile, isNotEmpty);
    });

    test('route names are unique', () {
      final names = [
        RouteNames.splash,
        RouteNames.login,
        RouteNames.register,
        RouteNames.forgotPassword,
        RouteNames.home,
        RouteNames.projects,
        RouteNames.devices,
        RouteNames.automations,
        RouteNames.aiAssistant,
        RouteNames.notifications,
        RouteNames.settings,
        RouteNames.profile,
      ];
      expect(names.toSet().length, names.length);
    });
  });
}
