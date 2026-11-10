import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_graph.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_node_type.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_validation.dart';

void main() {
  const validator = RuleGraphValidator();

  group('Integration: complete rule graph lifecycle', () {
    late RuleGraph completeGraph;

    setUp(() {
      completeGraph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'trigger_1',
            type: RuleNodeType.sensorAboveThreshold,
            position: const Offset(50, 100),
            config: {
              'device_id': 'device-abc-123',
              'sensor_key': 'temperature',
              'threshold': 30.0,
            },
            label: 'Temp > 30',
          ),
          RuleNode(
            id: 'cond_1',
            type: RuleNodeType.greaterThan,
            position: const Offset(300, 100),
            config: {'value': 25},
            label: 'Check > 25',
          ),
          RuleNode(
            id: 'action_1',
            type: RuleNodeType.sendCommand,
            position: const Offset(550, 100),
            config: {
              'device_id': 'device-xyz-789',
              'command_type': 'activate_cooling',
              'payload': {'fan_speed': 3},
            },
            label: 'Cool On',
          ),
        ],
        edges: const [
          RuleEdge(
            id: 'e1',
            sourceNodeId: 'trigger_1',
            sourcePort: 'out',
            targetNodeId: 'cond_1',
            targetPort: 'in',
          ),
          RuleEdge(
            id: 'e2',
            sourceNodeId: 'cond_1',
            sourcePort: 'out',
            targetNodeId: 'action_1',
            targetPort: 'in',
          ),
        ],
      );
    });

    test('complete graph validates with no errors', () {
      final errors = validator.validate(completeGraph);
      expect(errors, isEmpty);
    });

    test('serialize to JSON and deserialize preserves all fields', () {
      final json = completeGraph.toJson();
      final jsonString = jsonEncode(json);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = RuleGraph.fromJson(decoded);

      expect(restored.schemaVersion, completeGraph.schemaVersion);
      expect(restored.nodes.length, 3);
      expect(restored.edges.length, 2);

      final trigger = restored.findNode('trigger_1')!;
      expect(trigger.type, RuleNodeType.sensorAboveThreshold);
      expect(trigger.config['threshold'], 30.0);
      expect(trigger.label, 'Temp > 30');
      expect(trigger.position.dx, closeTo(50, 0.01));

      final condition = restored.findNode('cond_1')!;
      expect(condition.config['value'], 25);

      final action = restored.findNode('action_1')!;
      expect(action.config['command_type'], 'activate_cooling');
      expect((action.config['payload'] as Map)['fan_speed'], 3);

      final edge1 = restored.edges.first;
      expect(edge1.sourceNodeId, 'trigger_1');
      expect(edge1.targetNodeId, 'cond_1');
    });

    test('deserialized graph still validates with no errors', () {
      final json = completeGraph.toJson();
      final restored = RuleGraph.fromJson(json);
      final errors = validator.validate(restored);
      expect(errors, isEmpty);
    });

    test('graph with cycle: action back to condition', () {
      final cyclicGraph = RuleGraph(
        nodes: completeGraph.nodes,
        edges: [
          ...completeGraph.edges,
          const RuleEdge(
            id: 'e_cycle',
            sourceNodeId: 'action_1',
            sourcePort: 'out',
            targetNodeId: 'cond_1',
            targetPort: 'in',
          ),
        ],
      );
      final errors = validator.validate(cyclicGraph);
      expect(errors.any((e) => e.message.contains('Cycle detected')), isTrue);
    });

    test('graph with disconnected node', () {
      final disconnectedGraph = RuleGraph(
        nodes: [
          ...completeGraph.nodes,
          RuleNode(
            id: 'orphan',
            type: RuleNodeType.booleanCheck,
            position: const Offset(600, 300),
            config: {'expected': true},
          ),
        ],
        edges: completeGraph.edges,
      );
      final errors = validator.validate(disconnectedGraph);
      expect(
        errors.any(
          (e) => e.nodeId == 'orphan' && e.message.contains('not connected'),
        ),
        isTrue,
      );
    });
  });

  group('Integration: complex branching graph', () {
    test('conditional branch with true/false paths validates', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'trigger',
            type: RuleNodeType.manualTrigger,
            position: Offset.zero,
          ),
          RuleNode(
            id: 'cond',
            type: RuleNodeType.booleanCheck,
            position: const Offset(200, 0),
            config: {'expected': true},
          ),
          RuleNode(
            id: 'branch',
            type: RuleNodeType.conditionalBranch,
            position: const Offset(400, 0),
          ),
          RuleNode(
            id: 'action_true',
            type: RuleNodeType.logResult,
            position: const Offset(600, -50),
            config: {'message': 'Condition met'},
          ),
          RuleNode(
            id: 'action_false',
            type: RuleNodeType.logResult,
            position: const Offset(600, 50),
            config: {'message': 'Condition not met'},
          ),
        ],
        edges: const [
          RuleEdge(
            id: 'e1',
            sourceNodeId: 'trigger',
            sourcePort: 'out',
            targetNodeId: 'cond',
            targetPort: 'in',
          ),
          RuleEdge(
            id: 'e2',
            sourceNodeId: 'cond',
            sourcePort: 'out',
            targetNodeId: 'branch',
            targetPort: 'in',
          ),
          RuleEdge(
            id: 'e3',
            sourceNodeId: 'branch',
            sourcePort: 'true',
            targetNodeId: 'action_true',
            targetPort: 'in',
          ),
          RuleEdge(
            id: 'e4',
            sourceNodeId: 'branch',
            sourcePort: 'false',
            targetNodeId: 'action_false',
            targetPort: 'in',
          ),
        ],
      );
      final errors = validator.validate(graph);
      expect(errors, isEmpty);
    });
  });

  group('Integration: merge node', () {
    test('merge node with two inputs validates', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'trigger',
            type: RuleNodeType.manualTrigger,
            position: Offset.zero,
          ),
          RuleNode(
            id: 'cond_a',
            type: RuleNodeType.equalTo,
            position: const Offset(200, -50),
            config: {'value': 1},
          ),
          RuleNode(
            id: 'cond_b',
            type: RuleNodeType.equalTo,
            position: const Offset(200, 50),
            config: {'value': 2},
          ),
          RuleNode(
            id: 'm',
            type: RuleNodeType.merge,
            position: const Offset(400, 0),
          ),
          RuleNode(
            id: 'action',
            type: RuleNodeType.logResult,
            position: const Offset(600, 0),
            config: {'message': 'merged'},
          ),
        ],
        edges: const [
          RuleEdge(
            id: 'e1',
            sourceNodeId: 'trigger',
            sourcePort: 'out',
            targetNodeId: 'cond_a',
            targetPort: 'in',
          ),
          RuleEdge(
            id: 'e2',
            sourceNodeId: 'trigger',
            sourcePort: 'out',
            targetNodeId: 'cond_b',
            targetPort: 'in',
          ),
          RuleEdge(
            id: 'e3',
            sourceNodeId: 'cond_a',
            sourcePort: 'out',
            targetNodeId: 'm',
            targetPort: 'in_a',
          ),
          RuleEdge(
            id: 'e4',
            sourceNodeId: 'cond_b',
            sourcePort: 'out',
            targetNodeId: 'm',
            targetPort: 'in_b',
          ),
          RuleEdge(
            id: 'e5',
            sourceNodeId: 'm',
            sourcePort: 'out',
            targetNodeId: 'action',
            targetPort: 'in',
          ),
        ],
      );
      final errors = validator.validate(graph);
      expect(errors, isEmpty);
    });
  });
}
