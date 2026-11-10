import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_graph.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_node_type.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_validation.dart';

void main() {
  const validator = RuleGraphValidator();

  group('Security: graph import validation', () {
    test('unknown node type falls back to default via fromString', () {
      final node = RuleNode.fromJson({
        'id': 'n1',
        'type': 'malicious_eval_node',
        'position': {'x': 0, 'y': 0},
        'config': {},
      });
      expect(node.type, RuleNodeType.manualTrigger);
    });

    test('graph with 1000 nodes validates without crashing', () {
      final nodes = List.generate(
        1000,
        (i) => RuleNode(
          id: 'n$i',
          type: i == 0 ? RuleNodeType.manualTrigger : RuleNodeType.greaterThan,
          position: Offset(i * 10.0, 0),
          config: i == 0 ? {} : {'value': i},
        ),
      );

      final edges = <RuleEdge>[];
      for (int i = 0; i < 999; i++) {
        edges.add(
          RuleEdge(
            id: 'e$i',
            sourceNodeId: 'n$i',
            sourcePort: 'out',
            targetNodeId: 'n${i + 1}',
            targetPort: 'in',
          ),
        );
      }

      final graph = RuleGraph(nodes: nodes, edges: edges);
      final errors = validator.validate(graph);
      // Should run without timeout or crash. The second trigger check will flag
      // nodes n1–n999 as non-trigger but that's fine; the point is no crash.
      expect(errors, isNotNull);
    });

    test('graph with 100-level deep edge chain validates', () {
      final nodes = <RuleNode>[
        RuleNode(
          id: 'n0',
          type: RuleNodeType.manualTrigger,
          position: Offset.zero,
        ),
      ];
      for (int i = 1; i <= 100; i++) {
        nodes.add(
          RuleNode(
            id: 'n$i',
            type: RuleNodeType.logResult,
            position: Offset(i * 10.0, 0),
            config: {'message': 'level $i'},
          ),
        );
      }

      final edges = <RuleEdge>[];
      for (int i = 0; i < 100; i++) {
        edges.add(
          RuleEdge(
            id: 'e$i',
            sourceNodeId: 'n$i',
            sourcePort: 'out',
            targetNodeId: 'n${i + 1}',
            targetPort: 'in',
          ),
        );
      }

      final graph = RuleGraph(nodes: nodes, edges: edges);
      final errors = validator.validate(graph);
      expect(errors, isEmpty);
    });

    test('config with deeply nested JSON does not crash', () {
      Map<String, dynamic> nested = {'value': 1};
      for (int i = 0; i < 50; i++) {
        nested = {'inner': nested};
      }

      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.manualTrigger,
            position: Offset.zero,
            config: nested,
          ),
        ],
      );
      final errors = validator.validate(graph);
      expect(errors, isNotNull);
    });

    test('node label with XSS-like content is stored as-is', () {
      final node = RuleNode(
        id: 'n1',
        type: RuleNodeType.logResult,
        position: Offset.zero,
        config: {'message': 'test'},
        label: "<script>alert('xss')</script>",
      );

      final json = node.toJson();
      final restored = RuleNode.fromJson(json);
      expect(restored.label, "<script>alert('xss')</script>");
    });

    test(
      'empty config on node with required keys produces validation errors',
      () {
        final graph = RuleGraph(
          nodes: [
            RuleNode(
              id: 'n1',
              type: RuleNodeType.sendCommand,
              position: Offset.zero,
              config: {},
            ),
          ],
        );
        final errors = validator.validate(graph);
        final configErrors = errors.where(
          (e) => e.message.contains('missing required config'),
        );
        expect(configErrors.length, greaterThanOrEqualTo(2));
      },
    );

    test('null config values are handled gracefully', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.sensorAboveThreshold,
            position: Offset.zero,
            config: {'device_id': null, 'sensor_key': null, 'threshold': null},
          ),
        ],
      );
      final errors = validator.validate(graph);
      final configErrors = errors.where(
        (e) => e.message.contains('missing required config'),
      );
      expect(configErrors.length, 3);
    });

    test('graph JSON with missing nodes array is safe', () {
      final graph = RuleGraph.fromJson({'schema_version': 1});
      expect(graph.nodes, isEmpty);
      expect(graph.edges, isEmpty);
    });

    test('node fromJson with null position is safe', () {
      final node = RuleNode.fromJson({
        'id': 'n1',
        'type': 'manualTrigger',
        'position': null,
      });
      expect(node.position, Offset.zero);
    });
  });
}
