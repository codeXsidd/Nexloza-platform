import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexloza/features/alarms/domain/entities/alarm_configuration_entity.dart';
import 'package:nexloza/features/alarms/domain/entities/alarm_severity.dart';
import 'package:nexloza/features/alarms/domain/entities/alarm_source.dart';
import 'package:nexloza/features/alarms/domain/entities/alarm_activity_entity.dart';

void main() {
  Map<String, dynamic> makeConfigJson({
    String source = 'sensor_threshold',
    String conditionOperator = 'gt',
    double? thresholdValue = 80.0,
    bool hysteresisEnabled = false,
    double? hysteresisClearValue,
    int debounceSeconds = 0,
    int cooldownSeconds = 60,
    String severity = 'warning',
    bool isEnabled = true,
  }) => {
    'id': 'config-1',
    'project_id': 'proj-1',
    'device_id': 'dev-1',
    'organization_id': 'org-1',
    'name': 'High Temp Alert',
    'source': source,
    'sensor_key': 'temperature',
    'condition_operator': conditionOperator,
    'threshold_value': thresholdValue,
    'hysteresis_enabled': hysteresisEnabled,
    'hysteresis_clear_value': hysteresisClearValue,
    'debounce_seconds': debounceSeconds,
    'cooldown_seconds': cooldownSeconds,
    'severity': severity,
    'category': 'temperature',
    'message_template': 'Temperature is {{value}} (threshold: {{threshold}})',
    'is_enabled': isEnabled,
    'created_at': '2026-11-10T10:00:00Z',
    'updated_at': '2026-11-10T10:00:00Z',
  };

  group('AlarmConfiguration — fromJson', () {
    test('parses all fields correctly', () {
      final config = AlarmConfiguration.fromJson(makeConfigJson());
      expect(config.id, 'config-1');
      expect(config.projectId, 'proj-1');
      expect(config.deviceId, 'dev-1');
      expect(config.name, 'High Temp Alert');
      expect(config.source, AlarmSource.sensorThreshold);
      expect(config.sensorKey, 'temperature');
      expect(config.conditionOperator, 'gt');
      expect(config.thresholdValue, 80.0);
      expect(config.hysteresisEnabled, false);
      expect(config.debounceSeconds, 0);
      expect(config.cooldownSeconds, 60);
      expect(config.severity, AlarmSeverity.warning);
      expect(config.category, 'temperature');
      expect(config.messageTemplate, isNotNull);
      expect(config.isEnabled, true);
    });

    test('handles missing optional fields with defaults', () {
      final json = {
        'id': 'config-2',
        'project_id': 'proj-1',
        'organization_id': 'org-1',
        'name': 'Basic Config',
        'created_at': '2026-11-10T10:00:00Z',
        'updated_at': '2026-11-10T10:00:00Z',
      };
      final config = AlarmConfiguration.fromJson(json);
      expect(config.source, AlarmSource.sensorThreshold);
      expect(config.conditionOperator, 'gt');
      expect(config.hysteresisEnabled, false);
      expect(config.debounceSeconds, 0);
      expect(config.cooldownSeconds, 60);
      expect(config.severity, AlarmSeverity.warning);
      expect(config.category, 'general');
      expect(config.isEnabled, true);
      expect(config.deviceId, isNull);
      expect(config.sensorKey, isNull);
      expect(config.thresholdValue, isNull);
      expect(config.messageTemplate, isNull);
    });

    test('hysteresis fields are parsed', () {
      final config = AlarmConfiguration.fromJson(
        makeConfigJson(hysteresisEnabled: true, hysteresisClearValue: 75.0),
      );
      expect(config.hysteresisEnabled, true);
      expect(config.hysteresisClearValue, 75.0);
    });
  });

  group('AlarmConfiguration — operatorDisplayName', () {
    test('gt displays as >', () {
      final config = AlarmConfiguration.fromJson(
        makeConfigJson(conditionOperator: 'gt'),
      );
      expect(config.operatorDisplayName, '>');
    });

    test('gte displays as >=', () {
      final config = AlarmConfiguration.fromJson(
        makeConfigJson(conditionOperator: 'gte'),
      );
      expect(config.operatorDisplayName, '>=');
    });

    test('lt displays as <', () {
      final config = AlarmConfiguration.fromJson(
        makeConfigJson(conditionOperator: 'lt'),
      );
      expect(config.operatorDisplayName, '<');
    });

    test('lte displays as <=', () {
      final config = AlarmConfiguration.fromJson(
        makeConfigJson(conditionOperator: 'lte'),
      );
      expect(config.operatorDisplayName, '<=');
    });

    test('eq displays as =', () {
      final config = AlarmConfiguration.fromJson(
        makeConfigJson(conditionOperator: 'eq'),
      );
      expect(config.operatorDisplayName, '=');
    });

    test('neq displays as !=', () {
      final config = AlarmConfiguration.fromJson(
        makeConfigJson(conditionOperator: 'neq'),
      );
      expect(config.operatorDisplayName, '!=');
    });

    test('between displays as between', () {
      final config = AlarmConfiguration.fromJson(
        makeConfigJson(conditionOperator: 'between'),
      );
      expect(config.operatorDisplayName, 'between');
    });

    test('outside displays as outside', () {
      final config = AlarmConfiguration.fromJson(
        makeConfigJson(conditionOperator: 'outside'),
      );
      expect(config.operatorDisplayName, 'outside');
    });

    test('unknown operator returns raw value', () {
      final config = AlarmConfiguration.fromJson(
        makeConfigJson(conditionOperator: 'custom_op'),
      );
      expect(config.operatorDisplayName, 'custom_op');
    });
  });

  group('AlarmConfiguration — toJson', () {
    test('toJson includes all relevant fields', () {
      final config = AlarmConfiguration.fromJson(makeConfigJson());
      final json = config.toJson();
      expect(json['project_id'], 'proj-1');
      expect(json['device_id'], 'dev-1');
      expect(json['name'], 'High Temp Alert');
      expect(json['source'], 'sensor_threshold');
      expect(json['condition_operator'], 'gt');
      expect(json['threshold_value'], 80.0);
      expect(json['severity'], 'warning');
      expect(json['is_enabled'], true);
    });

    test('toJson excludes id, created_at, updated_at', () {
      final config = AlarmConfiguration.fromJson(makeConfigJson());
      final json = config.toJson();
      expect(json.containsKey('id'), false);
      expect(json.containsKey('created_at'), false);
      expect(json.containsKey('updated_at'), false);
    });
  });

  group('AlarmActivityType', () {
    test('has 7 values', () {
      expect(AlarmActivityType.values.length, 7);
    });

    test('all values have non-empty dbValue and displayName', () {
      for (final t in AlarmActivityType.values) {
        expect(t.dbValue, isNotEmpty);
        expect(t.displayName, isNotEmpty);
      }
    });

    test('fromString resolves all known types', () {
      expect(
        AlarmActivityType.fromString('created'),
        AlarmActivityType.created,
      );
      expect(
        AlarmActivityType.fromString('acknowledged'),
        AlarmActivityType.acknowledged,
      );
      expect(
        AlarmActivityType.fromString('escalated'),
        AlarmActivityType.escalated,
      );
      expect(
        AlarmActivityType.fromString('cleared'),
        AlarmActivityType.cleared,
      );
      expect(
        AlarmActivityType.fromString('severity_changed'),
        AlarmActivityType.severityChanged,
      );
      expect(
        AlarmActivityType.fromString('comment_added'),
        AlarmActivityType.commentAdded,
      );
      expect(
        AlarmActivityType.fromString('suppressed'),
        AlarmActivityType.suppressed,
      );
    });

    test('fromString returns created for unknown input', () {
      expect(
        AlarmActivityType.fromString('nonexistent'),
        AlarmActivityType.created,
      );
    });

    test('icons are distinct Material icons', () {
      expect(AlarmActivityType.created.icon, Icons.add_circle);
      expect(AlarmActivityType.acknowledged.icon, Icons.check_circle_outline);
      expect(AlarmActivityType.escalated.icon, Icons.trending_up);
      expect(AlarmActivityType.cleared.icon, Icons.check_circle);
      expect(AlarmActivityType.severityChanged.icon, Icons.swap_vert);
      expect(AlarmActivityType.commentAdded.icon, Icons.comment);
      expect(AlarmActivityType.suppressed.icon, Icons.do_not_disturb);
    });
  });

  group('AlarmActivity — fromJson', () {
    test('parses full activity with severity change', () {
      final json = {
        'id': 'act-1',
        'alarm_id': 'alarm-1',
        'activity_type': 'severity_changed',
        'performed_by': 'user-1',
        'comment': 'Upgrading severity',
        'previous_severity': 'warning',
        'new_severity': 'critical',
        'data': {'reason': 'escalation'},
        'created_at': '2026-11-10T10:15:00Z',
      };
      final activity = AlarmActivity.fromJson(json);
      expect(activity.activityType, AlarmActivityType.severityChanged);
      expect(activity.performedBy, 'user-1');
      expect(activity.comment, 'Upgrading severity');
      expect(activity.previousSeverity, AlarmSeverity.warning);
      expect(activity.newSeverity, AlarmSeverity.critical);
      expect(activity.data['reason'], 'escalation');
    });

    test('parses activity with null optional fields', () {
      final json = {
        'id': 'act-2',
        'alarm_id': 'alarm-1',
        'activity_type': 'created',
        'performed_by': null,
        'comment': null,
        'previous_severity': null,
        'new_severity': null,
        'data': null,
        'created_at': '2026-11-10T10:00:00Z',
      };
      final activity = AlarmActivity.fromJson(json);
      expect(activity.performedBy, isNull);
      expect(activity.comment, isNull);
      expect(activity.previousSeverity, isNull);
      expect(activity.newSeverity, isNull);
      expect(activity.data, isEmpty);
    });
  });
}
