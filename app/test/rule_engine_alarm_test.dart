import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexloza/features/rule_engine/domain/entities/rule_node_type.dart';

void main() {
  group('RuleNodeType — alarm action nodes', () {
    test('raiseAlarm exists and is action category', () {
      expect(RuleNodeType.raiseAlarm.category, RuleNodeCategory.action);
      expect(RuleNodeType.raiseAlarm.isAction, isTrue);
    });

    test('updateAlarmSeverity exists and is action category', () {
      expect(
        RuleNodeType.updateAlarmSeverity.category,
        RuleNodeCategory.action,
      );
      expect(RuleNodeType.updateAlarmSeverity.isAction, isTrue);
    });

    test('clearAlarm exists and is action category', () {
      expect(RuleNodeType.clearAlarm.category, RuleNodeCategory.action);
      expect(RuleNodeType.clearAlarm.isAction, isTrue);
    });

    test('addAlarmComment exists and is action category', () {
      expect(RuleNodeType.addAlarmComment.category, RuleNodeCategory.action);
      expect(RuleNodeType.addAlarmComment.isAction, isTrue);
    });

    test('total value count is 39 (35 original + 4 alarm actions)', () {
      expect(RuleNodeType.values.length, 39);
    });

    test('alarm node display names are correct', () {
      expect(RuleNodeType.raiseAlarm.displayName, 'Raise Alarm');
      expect(
        RuleNodeType.updateAlarmSeverity.displayName,
        'Update Alarm Severity',
      );
      expect(RuleNodeType.clearAlarm.displayName, 'Clear Alarm');
      expect(RuleNodeType.addAlarmComment.displayName, 'Add Alarm Comment');
    });

    test('alarm node descriptions are non-empty', () {
      expect(RuleNodeType.raiseAlarm.description, isNotEmpty);
      expect(RuleNodeType.updateAlarmSeverity.description, isNotEmpty);
      expect(RuleNodeType.clearAlarm.description, isNotEmpty);
      expect(RuleNodeType.addAlarmComment.description, isNotEmpty);
    });

    test('alarm node icons are correct', () {
      expect(RuleNodeType.raiseAlarm.icon, Icons.alarm_add);
      expect(RuleNodeType.updateAlarmSeverity.icon, Icons.swap_vert);
      expect(RuleNodeType.clearAlarm.icon, Icons.alarm_off);
      expect(RuleNodeType.addAlarmComment.icon, Icons.comment);
    });

    test('fromString resolves all 4 alarm node names', () {
      expect(RuleNodeType.fromString('raiseAlarm'), RuleNodeType.raiseAlarm);
      expect(
        RuleNodeType.fromString('updateAlarmSeverity'),
        RuleNodeType.updateAlarmSeverity,
      );
      expect(RuleNodeType.fromString('clearAlarm'), RuleNodeType.clearAlarm);
      expect(
        RuleNodeType.fromString('addAlarmComment'),
        RuleNodeType.addAlarmComment,
      );
    });
  });

  group('RuleNodeType — alarm node port definitions', () {
    test('all 4 alarm nodes have 1 input port with id "in"', () {
      for (final type in [
        RuleNodeType.raiseAlarm,
        RuleNodeType.updateAlarmSeverity,
        RuleNodeType.clearAlarm,
        RuleNodeType.addAlarmComment,
      ]) {
        expect(
          type.inputPorts.length,
          1,
          reason: '${type.name} should have 1 input port',
        );
        expect(
          type.inputPorts.first.id,
          'in',
          reason: '${type.name} input port id',
        );
      }
    });

    test('all 4 alarm nodes have 1 output port with id "out"', () {
      for (final type in [
        RuleNodeType.raiseAlarm,
        RuleNodeType.updateAlarmSeverity,
        RuleNodeType.clearAlarm,
        RuleNodeType.addAlarmComment,
      ]) {
        expect(
          type.outputPorts.length,
          1,
          reason: '${type.name} should have 1 output port',
        );
        expect(
          type.outputPorts.first.id,
          'out',
          reason: '${type.name} output port id',
        );
      }
    });
  });

  group('RuleNodeType — alarm node required config keys', () {
    test('raiseAlarm requires alarm_key, severity, title', () {
      expect(RuleNodeType.raiseAlarm.requiredConfigKeys, [
        'alarm_key',
        'severity',
        'title',
      ]);
    });

    test('updateAlarmSeverity requires alarm_key, severity', () {
      expect(RuleNodeType.updateAlarmSeverity.requiredConfigKeys, [
        'alarm_key',
        'severity',
      ]);
    });

    test('clearAlarm requires alarm_key', () {
      expect(RuleNodeType.clearAlarm.requiredConfigKeys, ['alarm_key']);
    });

    test('addAlarmComment requires alarm_key, comment', () {
      expect(RuleNodeType.addAlarmComment.requiredConfigKeys, [
        'alarm_key',
        'comment',
      ]);
    });
  });

  group('RuleNodeType — alarm nodes dbValue', () {
    test('dbValue matches enum name for all alarm nodes', () {
      expect(RuleNodeType.raiseAlarm.dbValue, 'raiseAlarm');
      expect(RuleNodeType.updateAlarmSeverity.dbValue, 'updateAlarmSeverity');
      expect(RuleNodeType.clearAlarm.dbValue, 'clearAlarm');
      expect(RuleNodeType.addAlarmComment.dbValue, 'addAlarmComment');
    });
  });
}
