import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_node_type.dart';

void main() {
  group('RuleNodeType', () {
    test('has exactly 39 values', () {
      expect(RuleNodeType.values.length, 39);
    });

    test('every value has non-empty displayName, description, dbValue', () {
      for (final t in RuleNodeType.values) {
        expect(t.displayName, isNotEmpty, reason: '${t.name} displayName');
        expect(t.description, isNotEmpty, reason: '${t.name} description');
        expect(t.dbValue, isNotEmpty, reason: '${t.name} dbValue');
      }
    });

    test('category counts: 11 triggers, 13 conditions, 11 actions, 4 flow', () {
      final triggers = RuleNodeType.values.where(
        (t) => t.category == RuleNodeCategory.trigger,
      );
      final conditions = RuleNodeType.values.where(
        (t) => t.category == RuleNodeCategory.condition,
      );
      final actions = RuleNodeType.values.where(
        (t) => t.category == RuleNodeCategory.action,
      );
      final flow = RuleNodeType.values.where(
        (t) => t.category == RuleNodeCategory.flow,
      );

      expect(triggers.length, 11);
      expect(conditions.length, 13);
      expect(actions.length, 11);
      expect(flow.length, 4);
    });

    test('isTrigger/isCondition/isAction/isFlow classify correctly', () {
      expect(RuleNodeType.telemetryReceived.isTrigger, isTrue);
      expect(RuleNodeType.telemetryReceived.isCondition, isFalse);
      expect(RuleNodeType.greaterThan.isCondition, isTrue);
      expect(RuleNodeType.greaterThan.isTrigger, isFalse);
      expect(RuleNodeType.sendCommand.isAction, isTrue);
      expect(RuleNodeType.sendCommand.isFlow, isFalse);
      expect(RuleNodeType.delay.isFlow, isTrue);
      expect(RuleNodeType.delay.isAction, isFalse);
    });

    test('fromString round-trips for all values', () {
      for (final t in RuleNodeType.values) {
        final restored = RuleNodeType.fromString(t.dbValue);
        expect(restored, t, reason: t.name);
      }
    });

    test('fromString unknown returns manualTrigger', () {
      expect(
        RuleNodeType.fromString('nonexistent'),
        RuleNodeType.manualTrigger,
      );
      expect(RuleNodeType.fromString(''), RuleNodeType.manualTrigger);
    });
  });

  group('RuleNodeCategory', () {
    test('has exactly 4 values', () {
      expect(RuleNodeCategory.values.length, 4);
    });

    test('each has displayName, icon, color', () {
      for (final c in RuleNodeCategory.values) {
        expect(c.displayName, isNotEmpty, reason: '${c.name} displayName');
        expect(c.icon, isNotNull, reason: '${c.name} icon');
        expect(c.color, isNotNull, reason: '${c.name} color');
      }
    });
  });

  group('PortDataType.canConnectTo', () {
    test('any connects to any', () {
      expect(PortDataType.any.canConnectTo(PortDataType.any), isTrue);
    });

    test('any connects to boolean', () {
      expect(PortDataType.any.canConnectTo(PortDataType.boolean), isTrue);
    });

    test('boolean connects to any', () {
      expect(PortDataType.boolean.canConnectTo(PortDataType.any), isTrue);
    });

    test('same type connects to same type', () {
      expect(PortDataType.boolean.canConnectTo(PortDataType.boolean), isTrue);
      expect(PortDataType.number.canConnectTo(PortDataType.number), isTrue);
      expect(PortDataType.string.canConnectTo(PortDataType.string), isTrue);
      expect(PortDataType.event.canConnectTo(PortDataType.event), isTrue);
    });

    test('boolean cannot connect to number', () {
      expect(PortDataType.boolean.canConnectTo(PortDataType.number), isFalse);
    });

    test('string cannot connect to boolean', () {
      expect(PortDataType.string.canConnectTo(PortDataType.boolean), isFalse);
    });

    test('event can connect to non-event (one-way compatibility)', () {
      expect(PortDataType.event.canConnectTo(PortDataType.boolean), isTrue);
      expect(PortDataType.event.canConnectTo(PortDataType.number), isTrue);
    });
  });

  group('NodePortDef', () {
    test('constructor sets all fields', () {
      const port = NodePortDef(
        id: 'out',
        label: 'Output',
        dataType: PortDataType.boolean,
      );
      expect(port.id, 'out');
      expect(port.label, 'Output');
      expect(port.dataType, PortDataType.boolean);
    });
  });
}
