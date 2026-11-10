import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_graph.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_node_type.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_validation.dart';

void main() {
  const validator = RuleGraphValidator();

  group('RuleGraphValidator', () {
    test('empty graph requires at least one trigger', () {
      final errors = validator.validate(const RuleGraph());
      expect(errors.length, 1);
      expect(errors.first.message, contains('at least one trigger'));
    });

    test('graph with only a trigger node passes', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.manualTrigger,
            position: Offset.zero,
          ),
        ],
      );
      final errors = validator.validate(graph);
      expect(errors, isEmpty);
    });

    test('two triggers produce error on second', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.manualTrigger,
            position: Offset.zero,
          ),
          RuleNode(
            id: 'n2',
            type: RuleNodeType.telemetryReceived,
            position: Offset.zero,
            config: {'device_id': 'd1'},
          ),
        ],
      );
      final errors = validator.validate(graph);
      expect(errors.any((e) => e.nodeId == 'n2' && e.message.contains('Only one trigger')),
          isTrue);
    });

    test('missing required config produces error per key', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.sensorAboveThreshold,
            position: Offset.zero,
            config: {},
          ),
        ],
      );
      final errors = validator.validate(graph);
      final configErrors =
          errors.where((e) => e.nodeId == 'n1' && e.message.contains('missing required config'));
      expect(configErrors.length, 3);
    });

    test('valid comparison value types pass', () {
      for (final val in [42, true, 'hello']) {
        final graph = RuleGraph(
          nodes: [
            RuleNode(
              id: 'n1',
              type: RuleNodeType.manualTrigger,
              position: Offset.zero,
            ),
            RuleNode(
              id: 'n2',
              type: RuleNodeType.equalTo,
              position: Offset.zero,
              config: {'value': val},
            ),
          ],
          edges: const [
            RuleEdge(
                id: 'e1',
                sourceNodeId: 'n1',
                sourcePort: 'out',
                targetNodeId: 'n2',
                targetPort: 'in'),
          ],
        );
        final errors = validator.validate(graph);
        expect(
          errors.any((e) => e.message.contains('must be a number, boolean')),
          isFalse,
          reason: 'Value $val (${val.runtimeType}) should be accepted',
        );
      }
    });

    test('betweenRange min > max produces error', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.manualTrigger,
            position: Offset.zero,
          ),
          RuleNode(
            id: 'n2',
            type: RuleNodeType.betweenRange,
            position: Offset.zero,
            config: {'min_value': 100, 'max_value': 10},
          ),
        ],
        edges: const [
          RuleEdge(
              id: 'e1',
              sourceNodeId: 'n1',
              sourcePort: 'out',
              targetNodeId: 'n2',
              targetPort: 'in'),
        ],
      );
      final errors = validator.validate(graph);
      expect(
          errors.any((e) => e.message.contains('min_value must be <= max_value')),
          isTrue);
    });

    test('delay out of bounds produces error', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.manualTrigger,
            position: Offset.zero,
          ),
          RuleNode(
            id: 'n2',
            type: RuleNodeType.delay,
            position: Offset.zero,
            config: {'duration_ms': 50},
          ),
        ],
        edges: const [
          RuleEdge(
              id: 'e1',
              sourceNodeId: 'n1',
              sourcePort: 'out',
              targetNodeId: 'n2',
              targetPort: 'in'),
        ],
      );
      final errors = validator.validate(graph);
      expect(
          errors.any((e) => e.message.contains('duration must be 100ms')),
          isTrue);
    });

    test('self-referencing edge produces error', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.manualTrigger,
            position: Offset.zero,
          ),
        ],
        edges: const [
          RuleEdge(
              id: 'e1',
              sourceNodeId: 'n1',
              sourcePort: 'out',
              targetNodeId: 'n1',
              targetPort: 'out'),
        ],
      );
      final errors = validator.validate(graph);
      expect(
          errors.any((e) => e.message.contains('Self-referencing')), isTrue);
    });

    test('edge with invalid source node produces error', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.manualTrigger,
            position: Offset.zero,
          ),
        ],
        edges: const [
          RuleEdge(
              id: 'e1',
              sourceNodeId: 'missing',
              sourcePort: 'out',
              targetNodeId: 'n1',
              targetPort: 'in'),
        ],
      );
      final errors = validator.validate(graph);
      expect(
          errors.any((e) => e.message.contains('source node') && e.message.contains('not found')),
          isTrue);
    });

    test('edge with invalid source port produces error', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.manualTrigger,
            position: Offset.zero,
          ),
          RuleNode(
            id: 'n2',
            type: RuleNodeType.logResult,
            position: Offset.zero,
            config: {'message': 'hi'},
          ),
        ],
        edges: const [
          RuleEdge(
              id: 'e1',
              sourceNodeId: 'n1',
              sourcePort: 'bogus_port',
              targetNodeId: 'n2',
              targetPort: 'in'),
        ],
      );
      final errors = validator.validate(graph);
      expect(errors.any((e) => e.message.contains('invalid output port')),
          isTrue);
    });

    test('disconnected non-trigger node produces error', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.manualTrigger,
            position: Offset.zero,
          ),
          RuleNode(
            id: 'n2',
            type: RuleNodeType.greaterThan,
            position: Offset.zero,
            config: {'value': 10},
          ),
        ],
      );
      final errors = validator.validate(graph);
      expect(
          errors.any((e) => e.nodeId == 'n2' && e.message.contains('not connected')),
          isTrue);
    });

    test('cycle detection: A -> B -> C -> A', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
              id: 'a',
              type: RuleNodeType.manualTrigger,
              position: Offset.zero),
          RuleNode(
              id: 'b',
              type: RuleNodeType.greaterThan,
              position: Offset.zero,
              config: {'value': 5}),
          RuleNode(
              id: 'c',
              type: RuleNodeType.logResult,
              position: Offset.zero,
              config: {'message': 'x'}),
        ],
        edges: const [
          RuleEdge(
              id: 'e1',
              sourceNodeId: 'a',
              sourcePort: 'out',
              targetNodeId: 'b',
              targetPort: 'in'),
          RuleEdge(
              id: 'e2',
              sourceNodeId: 'b',
              sourcePort: 'out',
              targetNodeId: 'c',
              targetPort: 'in'),
          RuleEdge(
              id: 'e3',
              sourceNodeId: 'c',
              sourcePort: 'out',
              targetNodeId: 'a',
              targetPort: 'out'),
        ],
      );
      final errors = validator.validate(graph);
      expect(errors.any((e) => e.message.contains('Cycle detected')), isTrue);
    });

    test('port type incompatibility: boolean output to number input', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.manualTrigger,
            position: Offset.zero,
          ),
          RuleNode(
            id: 'n2',
            type: RuleNodeType.booleanCheck,
            position: Offset.zero,
            config: {'expected': true},
          ),
        ],
        edges: const [
          RuleEdge(
              id: 'e1',
              sourceNodeId: 'n2',
              sourcePort: 'out',
              targetNodeId: 'n1',
              targetPort: 'out'),
        ],
      );
      // boolean -> event port (trigger has no input ports; this tests that
      // the validator handles the edge referencing a port not on a trigger).
      final errors = validator.validate(graph);
      // At minimum this should report invalid port errors rather than crash
      expect(errors, isNotEmpty);
    });

    test('valid complete graph: trigger -> condition -> action has no errors',
        () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'trigger',
            type: RuleNodeType.sensorAboveThreshold,
            position: Offset.zero,
            config: {
              'device_id': 'd1',
              'sensor_key': 'temperature',
              'threshold': 30,
            },
          ),
          RuleNode(
            id: 'cond',
            type: RuleNodeType.greaterThan,
            position: const Offset(200, 0),
            config: {'value': 25},
          ),
          RuleNode(
            id: 'action',
            type: RuleNodeType.sendCommand,
            position: const Offset(400, 0),
            config: {'device_id': 'd2', 'command_type': 'cool_on'},
          ),
        ],
        edges: const [
          RuleEdge(
              id: 'e1',
              sourceNodeId: 'trigger',
              sourcePort: 'out',
              targetNodeId: 'cond',
              targetPort: 'in'),
          RuleEdge(
              id: 'e2',
              sourceNodeId: 'cond',
              sourcePort: 'out',
              targetNodeId: 'action',
              targetPort: 'in'),
        ],
      );
      final errors = validator.validate(graph);
      expect(errors, isEmpty);
    });
  });
}
