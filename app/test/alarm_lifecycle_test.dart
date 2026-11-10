import 'package:flutter_test/flutter_test.dart';

import 'package:nexloza/features/alarms/domain/entities/alarm_entity.dart';
import 'package:nexloza/features/alarms/domain/entities/alarm_severity.dart';
import 'package:nexloza/features/alarms/domain/entities/alarm_source.dart';

void main() {
  Map<String, dynamic> makeAlarmJson({
    String status = 'active',
    String severity = 'critical',
    String? acknowledgedBy,
    String? acknowledgedAt,
    String? clearedBy,
    String? clearedAt,
    String? clearedReason,
    String? escalationPolicyId,
    int? escalationStage,
    String? escalatedAt,
    int occurrenceCount = 1,
  }) => {
    'id': 'lifecycle-alarm',
    'alarm_key': 'lifecycle:proj1:dev1:temp',
    'project_id': 'proj1',
    'device_id': 'dev1',
    'organization_id': 'org1',
    'severity': severity,
    'status': status,
    'source': 'sensor_threshold',
    'title': 'Lifecycle Test',
    'message': 'Temperature exceeded threshold',
    'category': 'temperature',
    'condition_value': 85.0,
    'threshold_value': 80.0,
    'hysteresis_clear_value': 75.0,
    'acknowledged_by': acknowledgedBy,
    'acknowledged_at': acknowledgedAt,
    'cleared_by': clearedBy,
    'cleared_at': clearedAt,
    'cleared_reason': clearedReason,
    'occurrence_count': occurrenceCount,
    'first_occurred_at': '2026-01-01T00:00:00Z',
    'last_occurred_at': '2026-01-01T00:30:00Z',
    'data': {'sensor_key': 'temperature'},
    'escalation_policy_id': escalationPolicyId,
    'escalation_stage': escalationStage,
    'escalated_at': escalatedAt,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:30:00Z',
  };

  group('Alarm lifecycle — Active state', () {
    test('newly created alarm is active', () {
      final alarm = Alarm.fromJson(makeAlarmJson());
      expect(alarm.isActive, true);
      expect(alarm.isAcknowledged, false);
      expect(alarm.isCleared, false);
    });

    test('active alarm has no acknowledged/cleared timestamps', () {
      final alarm = Alarm.fromJson(makeAlarmJson());
      expect(alarm.acknowledgedBy, isNull);
      expect(alarm.acknowledgedAt, isNull);
      expect(alarm.clearedBy, isNull);
      expect(alarm.clearedAt, isNull);
    });

    test('cleared alarm has bounded duration', () {
      final alarm = Alarm.fromJson(
        makeAlarmJson(status: 'cleared', clearedAt: '2026-01-01T02:00:00Z'),
      );
      expect(alarm.duration.inMinutes, 120);
    });
  });

  group('Alarm lifecycle — Acknowledged state', () {
    test('acknowledged alarm is not active and not cleared', () {
      final alarm = Alarm.fromJson(
        makeAlarmJson(
          status: 'acknowledged',
          acknowledgedBy: 'user-1',
          acknowledgedAt: '2026-01-01T00:15:00Z',
        ),
      );
      expect(alarm.isActive, false);
      expect(alarm.isAcknowledged, true);
      expect(alarm.isCleared, false);
    });

    test('acknowledged alarm has acknowledgedBy and acknowledgedAt', () {
      final alarm = Alarm.fromJson(
        makeAlarmJson(
          status: 'acknowledged',
          acknowledgedBy: 'user-1',
          acknowledgedAt: '2026-01-01T00:15:00Z',
        ),
      );
      expect(alarm.acknowledgedBy, 'user-1');
      expect(alarm.acknowledgedAt, isNotNull);
    });

    test('acknowledged is NOT cleared — distinct states', () {
      final alarm = Alarm.fromJson(makeAlarmJson(status: 'acknowledged'));
      expect(alarm.isAcknowledged, true);
      expect(alarm.isCleared, false);
    });
  });

  group('Alarm lifecycle — Cleared state', () {
    test('cleared alarm is not active and not acknowledged', () {
      final alarm = Alarm.fromJson(
        makeAlarmJson(
          status: 'cleared',
          clearedBy: 'user-2',
          clearedAt: '2026-01-01T01:00:00Z',
          clearedReason: 'Issue resolved',
        ),
      );
      expect(alarm.isActive, false);
      expect(alarm.isAcknowledged, false);
      expect(alarm.isCleared, true);
    });

    test('cleared alarm has clearedBy, clearedAt, and reason', () {
      final alarm = Alarm.fromJson(
        makeAlarmJson(
          status: 'cleared',
          clearedBy: 'user-2',
          clearedAt: '2026-01-01T01:00:00Z',
          clearedReason: 'Issue resolved',
        ),
      );
      expect(alarm.clearedBy, 'user-2');
      expect(alarm.clearedAt, isNotNull);
      expect(alarm.clearedReason, 'Issue resolved');
    });

    test('cleared alarm duration is bounded by clearedAt', () {
      final alarm = Alarm.fromJson(
        makeAlarmJson(status: 'cleared', clearedAt: '2026-01-01T01:00:00Z'),
      );
      expect(alarm.duration.inMinutes, 60);
    });
  });

  group('Alarm lifecycle — Escalation', () {
    test('non-escalated alarm has isEscalated false', () {
      final alarm = Alarm.fromJson(makeAlarmJson());
      expect(alarm.isEscalated, false);
    });

    test('escalated alarm has policy, stage, and timestamp', () {
      final alarm = Alarm.fromJson(
        makeAlarmJson(
          escalationPolicyId: 'policy-1',
          escalationStage: 2,
          escalatedAt: '2026-01-01T00:20:00Z',
        ),
      );
      expect(alarm.isEscalated, true);
      expect(alarm.escalationPolicyId, 'policy-1');
      expect(alarm.escalationStage, 2);
      expect(alarm.escalatedAt, isNotNull);
    });

    test('alarm with policy but no escalatedAt is not escalated', () {
      final alarm = Alarm.fromJson(
        makeAlarmJson(escalationPolicyId: 'policy-1', escalationStage: 1),
      );
      expect(alarm.isEscalated, false);
    });
  });

  group('Alarm lifecycle — Severity levels', () {
    test('isCritical returns true only for critical severity', () {
      expect(
        Alarm.fromJson(makeAlarmJson(severity: 'critical')).isCritical,
        true,
      );
      expect(Alarm.fromJson(makeAlarmJson(severity: 'high')).isCritical, false);
      expect(
        Alarm.fromJson(makeAlarmJson(severity: 'medium')).isCritical,
        false,
      );
      expect(
        Alarm.fromJson(makeAlarmJson(severity: 'warning')).isCritical,
        false,
      );
      expect(
        Alarm.fromJson(makeAlarmJson(severity: 'informational')).isCritical,
        false,
      );
    });

    test('severity sort order is critical < high < medium < warning < informational', () {
      expect(
        AlarmSeverity.critical.sortOrder,
        lessThan(AlarmSeverity.high.sortOrder),
      );
      expect(
        AlarmSeverity.high.sortOrder,
        lessThan(AlarmSeverity.medium.sortOrder),
      );
      expect(
        AlarmSeverity.medium.sortOrder,
        lessThan(AlarmSeverity.warning.sortOrder),
      );
      expect(
        AlarmSeverity.warning.sortOrder,
        lessThan(AlarmSeverity.informational.sortOrder),
      );
    });
  });

  group('Alarm lifecycle — Deduplication (stable key)', () {
    test('same alarm key with higher occurrence count indicates dedup', () {
      final alarm = Alarm.fromJson(makeAlarmJson(occurrenceCount: 5));
      expect(alarm.occurrenceCount, 5);
      expect(alarm.alarmKey, 'lifecycle:proj1:dev1:temp');
    });

    test('generateAlarmKey produces stable output', () {
      final key1 = Alarm.generateAlarmKey(
        source: 'sensor_threshold',
        projectId: 'proj1',
        deviceId: 'dev1',
        sensorKey: 'temperature',
      );
      final key2 = Alarm.generateAlarmKey(
        source: 'sensor_threshold',
        projectId: 'proj1',
        deviceId: 'dev1',
        sensorKey: 'temperature',
      );
      expect(key1, key2);
    });

    test('different sensor keys produce different alarm keys', () {
      final key1 = Alarm.generateAlarmKey(
        source: 'sensor_threshold',
        projectId: 'proj1',
        deviceId: 'dev1',
        sensorKey: 'temperature',
      );
      final key2 = Alarm.generateAlarmKey(
        source: 'sensor_threshold',
        projectId: 'proj1',
        deviceId: 'dev1',
        sensorKey: 'humidity',
      );
      expect(key1, isNot(key2));
    });
  });

  group('Alarm lifecycle — Hysteresis', () {
    test('alarm preserves hysteresis clear value', () {
      final alarm = Alarm.fromJson(makeAlarmJson());
      expect(alarm.thresholdValue, 80.0);
      expect(alarm.hysteresisClearValue, 75.0);
      expect(alarm.conditionValue, 85.0);
    });

    test('clear value is below threshold (hysteresis band)', () {
      final alarm = Alarm.fromJson(makeAlarmJson());
      expect(alarm.hysteresisClearValue!, lessThan(alarm.thresholdValue!));
    });
  });

  group('Alarm lifecycle — toJson roundtrip', () {
    test('toJson preserves key fields', () {
      final alarm = Alarm.fromJson(makeAlarmJson());
      final json = alarm.toJson();
      expect(json['alarm_key'], 'lifecycle:proj1:dev1:temp');
      expect(json['severity'], 'critical');
      expect(json['status'], 'active');
      expect(json['source'], 'sensor_threshold');
      expect(json['category'], 'temperature');
      expect(json['occurrence_count'], 1);
    });

    test('toJson round-trips through fromJson', () {
      final original = Alarm.fromJson(makeAlarmJson());
      final json = original.toJson();
      json['id'] = original.id;
      json['organization_id'] = original.organizationId;
      json['created_at'] = original.createdAt.toIso8601String();
      json['updated_at'] = original.updatedAt.toIso8601String();
      final rebuilt = Alarm.fromJson(json);
      expect(rebuilt.id, original.id);
      expect(rebuilt.alarmKey, original.alarmKey);
      expect(rebuilt.severity, original.severity);
      expect(rebuilt.status, original.status);
    });
  });

  group('AlarmSource — all 9 sources', () {
    test('all sources have unique dbValues', () {
      final dbValues = AlarmSource.values.map((s) => s.dbValue).toSet();
      expect(dbValues.length, AlarmSource.values.length);
    });

    test('all sources have unique displayNames', () {
      final names = AlarmSource.values.map((s) => s.displayName).toSet();
      expect(names.length, AlarmSource.values.length);
    });

    test('known sources resolve via fromString', () {
      final sources = [
        'sensor_threshold',
        'device_offline',
        'rule_action',
        'repeated_telemetry',
        'stale_data',
        'twin_mismatch',
        'actuator_failure',
        'virtual_device_fault',
        'manual',
      ];
      for (final s in sources) {
        expect(AlarmSource.fromString(s).dbValue, s);
      }
    });
  });
}
