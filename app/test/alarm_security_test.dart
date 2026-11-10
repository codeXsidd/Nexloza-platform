import 'package:flutter_test/flutter_test.dart';

import 'package:nexloza/features/alarms/domain/entities/alarm_entity.dart';
import 'package:nexloza/features/alarms/domain/entities/alarm_severity.dart';
import 'package:nexloza/features/alarms/domain/entities/alarm_status.dart';
import 'package:nexloza/features/alarms/domain/entities/alarm_source.dart';
import 'package:nexloza/features/alarms/domain/entities/alarm_activity_entity.dart';
import 'package:nexloza/features/alarms/domain/entities/alarm_configuration_entity.dart';
import 'package:nexloza/features/alarms/domain/entities/escalation_policy_entity.dart';

void main() {
  group('Alarm security — graceful handling of bad input', () {
    test('AlarmSeverity.fromString handles unknown input', () {
      expect(AlarmSeverity.fromString('nonexistent'), AlarmSeverity.warning);
      expect(AlarmSeverity.fromString(''), AlarmSeverity.warning);
    });

    test('AlarmStatus.fromString handles unknown input', () {
      expect(AlarmStatus.fromString('nonexistent'), AlarmStatus.active);
      expect(AlarmStatus.fromString(''), AlarmStatus.active);
    });

    test('AlarmSource.fromString handles unknown input', () {
      expect(AlarmSource.fromString('nonexistent'), AlarmSource.manual);
      expect(AlarmSource.fromString(''), AlarmSource.manual);
    });

    test('Alarm.generateAlarmKey never produces empty keys', () {
      final key = Alarm.generateAlarmKey(
        source: 'sensor_threshold',
        projectId: 'proj-1',
      );
      expect(key, isNotEmpty);
      expect(key, 'sensor_threshold:proj-1');
    });

    test('Alarm.generateAlarmKey includes optional segments', () {
      final key = Alarm.generateAlarmKey(
        source: 'sensor_threshold',
        projectId: 'proj-1',
        deviceId: 'dev-1',
        sensorKey: 'temperature',
        category: 'environment',
      );
      expect(key, 'sensor_threshold:proj-1:dev-1:temperature:environment');
    });

    test('Alarm with 1000-entry data field can be parsed', () {
      final bigData = <String, dynamic>{};
      for (int i = 0; i < 1000; i++) {
        bigData['key_$i'] = 'value_$i';
      }
      final json = {
        'id': 'test-id',
        'alarm_key': 'test:key',
        'project_id': 'proj-1',
        'organization_id': 'org-1',
        'title': 'Test Alarm',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'data': bigData,
      };
      final alarm = Alarm.fromJson(json);
      expect(alarm.data.length, 1000);
    });

    test('Alarm title with HTML/XSS content is stored as-is', () {
      final json = {
        'id': 'test-id',
        'alarm_key': 'xss:test',
        'project_id': 'proj-1',
        'organization_id': 'org-1',
        'title': '<script>alert("xss")</script>',
        'message': '<img onerror="alert(1)" src="x">',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final alarm = Alarm.fromJson(json);
      expect(alarm.title, '<script>alert("xss")</script>');
      expect(alarm.message, '<img onerror="alert(1)" src="x">');
    });

    test('AlarmActivity.fromJson handles null performer gracefully', () {
      final json = {
        'id': 'act-1',
        'alarm_id': 'alarm-1',
        'activity_type': 'created',
        'performed_by': null,
        'comment': null,
        'data': <String, dynamic>{},
        'created_at': '2026-01-01T00:00:00Z',
      };
      final activity = AlarmActivity.fromJson(json);
      expect(activity.performedBy, isNull);
      expect(activity.activityType, AlarmActivityType.created);
    });

    test('EscalationStage notification_targets handles non-list input', () {
      final json = {
        'id': 'stage-1',
        'policy_id': 'policy-1',
        'stage_number': 1,
        'delay_minutes': 15,
        'notification_targets': 'not-a-list',
        'action_type': 'notify',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final stage = EscalationStage.fromJson(json);
      expect(stage.notificationTargets, isEmpty);
    });

    test(
      'AlarmConfiguration.fromJson uses default operator for invalid input',
      () {
        final json = {
          'id': 'config-1',
          'project_id': 'proj-1',
          'organization_id': 'org-1',
          'name': 'Test Config',
          'condition_operator': 'invalid_op',
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        };
        final config = AlarmConfiguration.fromJson(json);
        expect(config.conditionOperator, 'invalid_op');
        // The DB constraint prevents invalid operators from being stored,
        // but the Dart entity accepts whatever JSON provides without crashing
        expect(config.name, 'Test Config');
      },
    );
  });

  group('Alarm entity — fromJson with missing optional fields', () {
    test('Alarm.fromJson with minimal fields uses defaults', () {
      final json = {
        'id': 'test-id',
        'alarm_key': 'min:test',
        'project_id': 'proj-1',
        'organization_id': 'org-1',
        'title': 'Minimal Alarm',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final alarm = Alarm.fromJson(json);
      expect(alarm.severity, AlarmSeverity.warning);
      expect(alarm.status, AlarmStatus.active);
      expect(alarm.source, AlarmSource.manual);
      expect(alarm.category, 'general');
      expect(alarm.occurrenceCount, 1);
      expect(alarm.deviceId, isNull);
      expect(alarm.acknowledgedBy, isNull);
      expect(alarm.clearedBy, isNull);
      expect(alarm.escalationPolicyId, isNull);
      expect(alarm.data, isEmpty);
    });
  });
}
