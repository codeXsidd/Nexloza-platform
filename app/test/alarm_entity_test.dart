import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexloza/features/alarms/domain/entities/alarm_severity.dart';
import 'package:nexloza/features/alarms/domain/entities/alarm_status.dart';
import 'package:nexloza/features/alarms/domain/entities/alarm_source.dart';
import 'package:nexloza/features/alarms/domain/entities/alarm_entity.dart';

void main() {
  group('AlarmSeverity', () {
    test('has 5 values', () {
      expect(AlarmSeverity.values.length, 5);
    });

    test('critical has correct properties', () {
      expect(AlarmSeverity.critical.dbValue, 'critical');
      expect(AlarmSeverity.critical.displayName, 'Critical');
      expect(AlarmSeverity.critical.color, Colors.red);
      expect(AlarmSeverity.critical.icon, Icons.error);
      expect(AlarmSeverity.critical.sortOrder, 0);
    });

    test('high has correct properties', () {
      expect(AlarmSeverity.high.dbValue, 'high');
      expect(AlarmSeverity.high.displayName, 'High');
      expect(AlarmSeverity.high.color, Colors.deepOrange);
      expect(AlarmSeverity.high.sortOrder, 1);
    });

    test('medium has correct properties', () {
      expect(AlarmSeverity.medium.dbValue, 'medium');
      expect(AlarmSeverity.medium.displayName, 'Medium');
      expect(AlarmSeverity.medium.color, Colors.orange);
      expect(AlarmSeverity.medium.sortOrder, 2);
    });

    test('warning has correct properties', () {
      expect(AlarmSeverity.warning.dbValue, 'warning');
      expect(AlarmSeverity.warning.displayName, 'Warning');
      expect(AlarmSeverity.warning.color, Colors.amber);
      expect(AlarmSeverity.warning.sortOrder, 3);
    });

    test('informational has correct properties', () {
      expect(AlarmSeverity.informational.dbValue, 'informational');
      expect(AlarmSeverity.informational.displayName, 'Informational');
      expect(AlarmSeverity.informational.color, Colors.blue);
      expect(AlarmSeverity.informational.sortOrder, 4);
    });

    test('fromString resolves by dbValue', () {
      expect(AlarmSeverity.fromString('critical'), AlarmSeverity.critical);
      expect(AlarmSeverity.fromString('high'), AlarmSeverity.high);
      expect(AlarmSeverity.fromString('informational'), AlarmSeverity.informational);
    });

    test('fromString resolves by enum name', () {
      expect(AlarmSeverity.fromString('medium'), AlarmSeverity.medium);
      expect(AlarmSeverity.fromString('warning'), AlarmSeverity.warning);
    });

    test('fromString returns warning for invalid input', () {
      expect(AlarmSeverity.fromString('unknown'), AlarmSeverity.warning);
      expect(AlarmSeverity.fromString(''), AlarmSeverity.warning);
    });
  });

  group('AlarmStatus', () {
    test('has 3 values', () {
      expect(AlarmStatus.values.length, 3);
    });

    test('active has correct properties', () {
      expect(AlarmStatus.active.dbValue, 'active');
      expect(AlarmStatus.active.displayName, 'Active');
      expect(AlarmStatus.active.color, Colors.red);
      expect(AlarmStatus.active.icon, Icons.error);
    });

    test('acknowledged has correct properties', () {
      expect(AlarmStatus.acknowledged.dbValue, 'acknowledged');
      expect(AlarmStatus.acknowledged.displayName, 'Acknowledged');
      expect(AlarmStatus.acknowledged.color, Colors.orange);
      expect(AlarmStatus.acknowledged.icon, Icons.check_circle_outline);
    });

    test('cleared has correct properties', () {
      expect(AlarmStatus.cleared.dbValue, 'cleared');
      expect(AlarmStatus.cleared.displayName, 'Cleared');
      expect(AlarmStatus.cleared.color, Colors.green);
      expect(AlarmStatus.cleared.icon, Icons.check_circle);
    });

    test('fromString resolves by dbValue', () {
      expect(AlarmStatus.fromString('active'), AlarmStatus.active);
      expect(AlarmStatus.fromString('acknowledged'), AlarmStatus.acknowledged);
      expect(AlarmStatus.fromString('cleared'), AlarmStatus.cleared);
    });

    test('fromString returns active for invalid input', () {
      expect(AlarmStatus.fromString('bogus'), AlarmStatus.active);
      expect(AlarmStatus.fromString(''), AlarmStatus.active);
    });
  });

  group('AlarmSource', () {
    test('has 9 values', () {
      expect(AlarmSource.values.length, 9);
    });

    test('all values have non-empty dbValue and displayName', () {
      for (final s in AlarmSource.values) {
        expect(s.dbValue, isNotEmpty);
        expect(s.displayName, isNotEmpty);
      }
    });

    test('fromString resolves sensor_threshold', () {
      expect(AlarmSource.fromString('sensor_threshold'), AlarmSource.sensorThreshold);
    });

    test('fromString resolves device_offline', () {
      expect(AlarmSource.fromString('device_offline'), AlarmSource.deviceOffline);
    });

    test('fromString returns manual for invalid input', () {
      expect(AlarmSource.fromString('nonexistent'), AlarmSource.manual);
    });
  });

  group('Alarm.fromJson', () {
    Map<String, dynamic> fullAlarmJson() => {
          'id': 'alarm-001',
          'alarm_key': 'sensor_threshold:proj1:dev1:temperature',
          'project_id': 'proj1',
          'device_id': 'dev1',
          'organization_id': 'org1',
          'severity': 'critical',
          'status': 'active',
          'source': 'sensor_threshold',
          'title': 'Temperature High',
          'message': 'Exceeded 80C',
          'category': 'temperature',
          'condition_value': 85.0,
          'threshold_value': 80.0,
          'hysteresis_clear_value': 75.0,
          'acknowledged_by': null,
          'acknowledged_at': null,
          'cleared_by': null,
          'cleared_at': null,
          'cleared_reason': null,
          'occurrence_count': 3,
          'first_occurred_at': '2026-11-10T10:00:00Z',
          'last_occurred_at': '2026-11-10T10:30:00Z',
          'data': {'sensor_key': 'temperature'},
          'escalation_policy_id': 'esc-001',
          'escalation_stage': 2,
          'escalated_at': '2026-11-10T10:20:00Z',
          'created_at': '2026-11-10T10:00:00Z',
          'updated_at': '2026-11-10T10:30:00Z',
        };

    test('parses full JSON correctly', () {
      final alarm = Alarm.fromJson(fullAlarmJson());
      expect(alarm.id, 'alarm-001');
      expect(alarm.alarmKey, 'sensor_threshold:proj1:dev1:temperature');
      expect(alarm.severity, AlarmSeverity.critical);
      expect(alarm.status, AlarmStatus.active);
      expect(alarm.source, AlarmSource.sensorThreshold);
      expect(alarm.title, 'Temperature High');
      expect(alarm.message, 'Exceeded 80C');
      expect(alarm.conditionValue, 85.0);
      expect(alarm.thresholdValue, 80.0);
      expect(alarm.hysteresisClearValue, 75.0);
      expect(alarm.occurrenceCount, 3);
      expect(alarm.escalationPolicyId, 'esc-001');
      expect(alarm.escalationStage, 2);
      expect(alarm.escalatedAt, isNotNull);
    });

    test('handles nullable fields', () {
      final json = fullAlarmJson();
      json['device_id'] = null;
      json['message'] = null;
      json['condition_value'] = null;
      json['threshold_value'] = null;
      json['escalation_policy_id'] = null;
      json['escalation_stage'] = null;
      json['escalated_at'] = null;

      final alarm = Alarm.fromJson(json);
      expect(alarm.deviceId, isNull);
      expect(alarm.message, isNull);
      expect(alarm.conditionValue, isNull);
      expect(alarm.escalationPolicyId, isNull);
      expect(alarm.isEscalated, false);
    });
  });

  group('Alarm computed properties', () {
    Alarm alarmWithStatus(String status) => Alarm.fromJson({
          'id': 'a1',
          'alarm_key': 'k1',
          'project_id': 'p1',
          'organization_id': 'o1',
          'severity': 'critical',
          'status': status,
          'source': 'manual',
          'title': 'Test',
          'category': 'general',
          'occurrence_count': 1,
          'first_occurred_at': '2026-11-10T10:00:00Z',
          'last_occurred_at': '2026-11-10T10:00:00Z',
          'data': <String, dynamic>{},
          'created_at': '2026-11-10T10:00:00Z',
          'updated_at': '2026-11-10T10:00:00Z',
        });

    test('isActive is true only for active', () {
      expect(alarmWithStatus('active').isActive, true);
      expect(alarmWithStatus('acknowledged').isActive, false);
      expect(alarmWithStatus('cleared').isActive, false);
    });

    test('isAcknowledged is true only for acknowledged', () {
      expect(alarmWithStatus('acknowledged').isAcknowledged, true);
      expect(alarmWithStatus('active').isAcknowledged, false);
    });

    test('isCleared is true only for cleared', () {
      expect(alarmWithStatus('cleared').isCleared, true);
      expect(alarmWithStatus('active').isCleared, false);
    });

    test('isCritical checks severity', () {
      expect(alarmWithStatus('active').isCritical, true);
    });
  });

  group('Alarm.generateAlarmKey', () {
    test('generates key from source and project', () {
      final key = Alarm.generateAlarmKey(
        source: 'sensor_threshold',
        projectId: 'proj1',
      );
      expect(key, 'sensor_threshold:proj1');
    });

    test('includes device when provided', () {
      final key = Alarm.generateAlarmKey(
        source: 'device_offline',
        projectId: 'proj1',
        deviceId: 'dev1',
      );
      expect(key, 'device_offline:proj1:dev1');
    });

    test('includes all components when provided', () {
      final key = Alarm.generateAlarmKey(
        source: 'sensor_threshold',
        projectId: 'proj1',
        deviceId: 'dev1',
        sensorKey: 'temperature',
        category: 'environmental',
      );
      expect(key, 'sensor_threshold:proj1:dev1:temperature:environmental');
    });
  });

  group('AlarmStats', () {
    test('empty factory returns all zeros', () {
      final stats = AlarmStats.empty();
      expect(stats.totalActive, 0);
      expect(stats.criticalCount, 0);
      expect(stats.highCount, 0);
      expect(stats.mediumCount, 0);
      expect(stats.warningCount, 0);
      expect(stats.informationalCount, 0);
      expect(stats.acknowledgedCount, 0);
      expect(stats.unacknowledgedCount, 0);
    });

    test('fromAlarms computes correct counts', () {
      Alarm makeAlarm(String status, String severity) => Alarm.fromJson({
            'id': '${status}_$severity',
            'alarm_key': 'k_${status}_$severity',
            'project_id': 'p1',
            'organization_id': 'o1',
            'severity': severity,
            'status': status,
            'source': 'manual',
            'title': 'Test',
            'category': 'general',
            'occurrence_count': 1,
            'first_occurred_at': '2026-11-10T10:00:00Z',
            'last_occurred_at': '2026-11-10T10:00:00Z',
            'data': <String, dynamic>{},
            'created_at': '2026-11-10T10:00:00Z',
            'updated_at': '2026-11-10T10:00:00Z',
          });

      final alarms = [
        makeAlarm('active', 'critical'),
        makeAlarm('active', 'high'),
        makeAlarm('acknowledged', 'medium'),
        makeAlarm('cleared', 'warning'),
        makeAlarm('active', 'informational'),
      ];

      final stats = AlarmStats.fromAlarms(alarms);
      expect(stats.totalActive, 4);
      expect(stats.criticalCount, 1);
      expect(stats.highCount, 1);
      expect(stats.mediumCount, 1);
      expect(stats.warningCount, 0);
      expect(stats.informationalCount, 1);
      expect(stats.acknowledgedCount, 1);
      expect(stats.unacknowledgedCount, 3);
    });

    test('fromAlarms with empty list', () {
      final stats = AlarmStats.fromAlarms([]);
      expect(stats.totalActive, 0);
      expect(stats.criticalCount, 0);
    });
  });
}
