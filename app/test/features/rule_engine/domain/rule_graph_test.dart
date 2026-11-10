import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_graph.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_node_type.dart';

void main() {
  group('RuleNode', () {
    test('constructor sets all fields', () {
      final node = RuleNode(
        id: 'n1',
        type: RuleNodeType.sendCommand,
        position: const Offset(10, 20),
        config: {'device_id': 'abc'},
        label: 'My Node',
      );
      expect(node.id, 'n1');
      expect(node.type, RuleNodeType.sendCommand);
      expect(node.position, const Offset(10, 20));
      expect(node.config['device_id'], 'abc');
      expect(node.label, 'My Node');
    });

    test('copyWith position', () {
      final node = RuleNode(
        id: 'n1',
        type: RuleNodeType.delay,
        position: const Offset(0, 0),
      );
      final moved = node.copyWith(position: const Offset(50, 60));
      expect(moved.position, const Offset(50, 60));
      expect(moved.id, 'n1');
      expect(moved.type, RuleNodeType.delay);
    });

    test('copyWith config', () {
      final node = RuleNode(
        id: 'n1',
        type: RuleNodeType.greaterThan,
        position: const Offset(0, 0),
        config: {'value': 10},
      );
      final updated = node.copyWith(config: {'value': 42});
      expect(updated.config['value'], 42);
      expect(updated.id, 'n1');
    });

    test('copyWith label', () {
      final node = RuleNode(
        id: 'n1',
        type: RuleNodeType.logResult,
        position: Offset.zero,
        label: 'old',
      );
      final updated = node.copyWith(label: 'new');
      expect(updated.label, 'new');
    });

    test('toJson and fromJson round-trip', () {
      final node = RuleNode(
        id: 'n1',
        type: RuleNodeType.sensorAboveThreshold,
        position: const Offset(100.5, 200.5),
        config: {'device_id': 'd1', 'sensor_key': 'temp', 'threshold': 30},
        label: 'Temp Check',
      );
      final json = node.toJson();
      final restored = RuleNode.fromJson(json);
      expect(restored.id, node.id);
      expect(restored.type, node.type);
      expect(restored.position.dx, closeTo(100.5, 0.01));
      expect(restored.position.dy, closeTo(200.5, 0.01));
      expect(restored.config['threshold'], 30);
      expect(restored.label, 'Temp Check');
    });

    test('fromJson with missing fields uses defaults', () {
      final node = RuleNode.fromJson({'id': 'n2', 'type': 'manualTrigger'});
      expect(node.id, 'n2');
      expect(node.position, Offset.zero);
      expect(node.config, isEmpty);
      expect(node.label, '');
    });
  });

  group('RuleEdge', () {
    test('constructor sets all fields', () {
      const edge = RuleEdge(
        id: 'e1',
        sourceNodeId: 'n1',
        sourcePort: 'out',
        targetNodeId: 'n2',
        targetPort: 'in',
      );
      expect(edge.id, 'e1');
      expect(edge.sourceNodeId, 'n1');
      expect(edge.sourcePort, 'out');
      expect(edge.targetNodeId, 'n2');
      expect(edge.targetPort, 'in');
    });

    test('toJson and fromJson round-trip', () {
      const edge = RuleEdge(
        id: 'e1',
        sourceNodeId: 'n1',
        sourcePort: 'out',
        targetNodeId: 'n2',
        targetPort: 'in_a',
      );
      final json = edge.toJson();
      final restored = RuleEdge.fromJson(json);
      expect(restored.id, 'e1');
      expect(restored.sourceNodeId, 'n1');
      expect(restored.sourcePort, 'out');
      expect(restored.targetNodeId, 'n2');
      expect(restored.targetPort, 'in_a');
    });
  });

  group('RuleGraph', () {
    test('constructor defaults', () {
      const graph = RuleGraph();
      expect(graph.schemaVersion, currentGraphSchemaVersion);
      expect(graph.nodes, isEmpty);
      expect(graph.edges, isEmpty);
    });

    test('fromJson and toJson round-trip', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.manualTrigger,
            position: const Offset(10, 20),
          ),
          RuleNode(
            id: 'n2',
            type: RuleNodeType.logResult,
            position: const Offset(200, 20),
            config: {'message': 'hello'},
          ),
        ],
        edges: const [
          RuleEdge(
            id: 'e1',
            sourceNodeId: 'n1',
            sourcePort: 'out',
            targetNodeId: 'n2',
            targetPort: 'in',
          ),
        ],
      );
      final json = graph.toJson();
      final restored = RuleGraph.fromJson(json);
      expect(restored.schemaVersion, graph.schemaVersion);
      expect(restored.nodes.length, 2);
      expect(restored.edges.length, 1);
      expect(restored.nodes[1].config['message'], 'hello');
    });

    test('findNode returns node when present', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(id: 'n1', type: RuleNodeType.delay, position: Offset.zero),
        ],
      );
      expect(graph.findNode('n1'), isNotNull);
      expect(graph.findNode('n1')!.id, 'n1');
    });

    test('findNode returns null when absent', () {
      const graph = RuleGraph();
      expect(graph.findNode('missing'), isNull);
    });

    test('edgesFrom returns outgoing edges', () {
      const graph = RuleGraph(
        edges: [
          RuleEdge(
            id: 'e1',
            sourceNodeId: 'n1',
            sourcePort: 'out',
            targetNodeId: 'n2',
            targetPort: 'in',
          ),
          RuleEdge(
            id: 'e2',
            sourceNodeId: 'n1',
            sourcePort: 'out',
            targetNodeId: 'n3',
            targetPort: 'in',
          ),
          RuleEdge(
            id: 'e3',
            sourceNodeId: 'n2',
            sourcePort: 'out',
            targetNodeId: 'n3',
            targetPort: 'in',
          ),
        ],
      );
      expect(graph.edgesFrom('n1').length, 2);
      expect(graph.edgesFrom('n3').length, 0);
    });

    test('edgesTo returns incoming edges', () {
      const graph = RuleGraph(
        edges: [
          RuleEdge(
            id: 'e1',
            sourceNodeId: 'n1',
            sourcePort: 'out',
            targetNodeId: 'n3',
            targetPort: 'in',
          ),
          RuleEdge(
            id: 'e2',
            sourceNodeId: 'n2',
            sourcePort: 'out',
            targetNodeId: 'n3',
            targetPort: 'in_b',
          ),
        ],
      );
      expect(graph.edgesTo('n3').length, 2);
      expect(graph.edgesTo('n1').length, 0);
    });

    test('triggerNodes returns only trigger-category nodes', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.telemetryReceived,
            position: Offset.zero,
          ),
          RuleNode(
            id: 'n2',
            type: RuleNodeType.greaterThan,
            position: Offset.zero,
          ),
          RuleNode(
            id: 'n3',
            type: RuleNodeType.sendCommand,
            position: Offset.zero,
          ),
        ],
      );
      final triggers = graph.triggerNodes;
      expect(triggers.length, 1);
      expect(triggers.first.id, 'n1');
    });

    test('empty constant has no nodes or edges', () {
      expect(RuleGraph.empty.nodes, isEmpty);
      expect(RuleGraph.empty.edges, isEmpty);
    });
  });

  group('RuleStatus', () {
    test('fromString resolves all 6 values', () {
      expect(RuleStatus.fromString('draft'), RuleStatus.draft);
      expect(RuleStatus.fromString('validated'), RuleStatus.validated);
      expect(RuleStatus.fromString('published'), RuleStatus.published);
      expect(RuleStatus.fromString('enabled'), RuleStatus.enabled);
      expect(RuleStatus.fromString('disabled'), RuleStatus.disabled);
      expect(RuleStatus.fromString('archived'), RuleStatus.archived);
    });

    test('fromString unknown defaults to draft', () {
      expect(RuleStatus.fromString('bogus'), RuleStatus.draft);
      expect(RuleStatus.fromString(''), RuleStatus.draft);
    });

    test('isEditable: draft and validated are true', () {
      expect(RuleStatus.draft.isEditable, isTrue);
      expect(RuleStatus.validated.isEditable, isTrue);
      expect(RuleStatus.published.isEditable, isFalse);
      expect(RuleStatus.enabled.isEditable, isFalse);
      expect(RuleStatus.disabled.isEditable, isFalse);
      expect(RuleStatus.archived.isEditable, isFalse);
    });

    test('isActive: only enabled is true', () {
      expect(RuleStatus.enabled.isActive, isTrue);
      for (final s in RuleStatus.values.where((s) => s != RuleStatus.enabled)) {
        expect(s.isActive, isFalse);
      }
    });

    test('canPublish: only validated is true', () {
      expect(RuleStatus.validated.canPublish, isTrue);
      for (final s in RuleStatus.values.where(
        (s) => s != RuleStatus.validated,
      )) {
        expect(s.canPublish, isFalse);
      }
    });

    test('canEnable: published and disabled are true', () {
      expect(RuleStatus.published.canEnable, isTrue);
      expect(RuleStatus.disabled.canEnable, isTrue);
      expect(RuleStatus.draft.canEnable, isFalse);
      expect(RuleStatus.validated.canEnable, isFalse);
      expect(RuleStatus.enabled.canEnable, isFalse);
      expect(RuleStatus.archived.canEnable, isFalse);
    });

    test('displayName for each value', () {
      expect(RuleStatus.draft.displayName, 'Draft');
      expect(RuleStatus.validated.displayName, 'Validated');
      expect(RuleStatus.published.displayName, 'Published');
      expect(RuleStatus.enabled.displayName, 'Enabled');
      expect(RuleStatus.disabled.displayName, 'Disabled');
      expect(RuleStatus.archived.displayName, 'Archived');
    });
  });

  group('RuleVersion', () {
    test('fromJson parses all fields', () {
      final version = RuleVersion.fromJson({
        'id': 'v1',
        'automation_id': 'a1',
        'version_number': 3,
        'graph_snapshot': {'schema_version': 1, 'nodes': [], 'edges': []},
        'published_at': '2026-11-10T12:00:00Z',
        'published_by': 'user1',
      });
      expect(version.id, 'v1');
      expect(version.automationId, 'a1');
      expect(version.versionNumber, 3);
      expect(version.graphSnapshot.nodes, isEmpty);
      expect(version.publishedBy, 'user1');
    });
  });
}
