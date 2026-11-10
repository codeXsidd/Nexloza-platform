import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_graph.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_node_type.dart';
import 'package:nexloza/features/rule_engine/presentation/providers/rule_provider.dart';

void main() {
  late ProviderContainer container;
  late RuleEditorNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(ruleEditorProvider.notifier);
  });

  tearDown(() => container.dispose());

  RuleEditorState rs() => container.read(ruleEditorProvider);

  group('RuleEditorNotifier', () {
    test('initial state is empty', () {
      expect(rs().nodes, isEmpty);
      expect(rs().edges, isEmpty);
      expect(rs().selectedNodeId, isNull);
      expect(rs().isDirty, isFalse);
      expect(rs().canUndo, isFalse);
      expect(rs().canRedo, isFalse);
      expect(rs().validationErrors, isEmpty);
    });

    test('loadGraph populates nodes and edges', () {
      final graph = RuleGraph(
        nodes: [
          RuleNode(
            id: 'n1',
            type: RuleNodeType.manualTrigger,
            position: Offset.zero,
            label: 'Trigger',
          ),
          RuleNode(
            id: 'n2',
            type: RuleNodeType.logResult,
            position: const Offset(200, 0),
            config: {'message': 'test'},
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
      notifier.loadGraph(graph);

      expect(rs().nodes.length, 2);
      expect(rs().edges.length, 1);
      expect(rs().nodes['n1']!.type, RuleNodeType.manualTrigger);
      expect(rs().edges['e1']!.sourceNodeId, 'n1');
    });

    test('addNode generates unique id and stores node', () {
      final id1 = notifier.addNode(RuleNodeType.manualTrigger, Offset.zero);
      final id2 =
          notifier.addNode(RuleNodeType.greaterThan, const Offset(100, 0));
      expect(id1, isNot(id2));
      expect(rs().nodes.length, 2);
      expect(rs().nodes[id1]!.type, RuleNodeType.manualTrigger);
      expect(rs().nodes[id2]!.type, RuleNodeType.greaterThan);
    });

    test('addNode pushes to undo stack', () {
      expect(rs().canUndo, isFalse);
      notifier.addNode(RuleNodeType.delay, Offset.zero);
      expect(rs().canUndo, isTrue);
    });

    test('moveNode updates position with delta', () {
      final id =
          notifier.addNode(RuleNodeType.manualTrigger, const Offset(10, 20));
      notifier.moveNode(id, const Offset(5, -3));
      expect(rs().nodes[id]!.position, const Offset(15, 17));
    });

    test('updateNodeConfig replaces config', () {
      final id = notifier.addNode(RuleNodeType.greaterThan, Offset.zero);
      notifier.updateNodeConfig(id, {'value': 42});
      expect(rs().nodes[id]!.config['value'], 42);
    });

    test('deleteNode removes node and connected edges', () {
      notifier.loadGraph(RuleGraph(
        nodes: [
          RuleNode(
              id: 'n1',
              type: RuleNodeType.manualTrigger,
              position: Offset.zero),
          RuleNode(
              id: 'n2',
              type: RuleNodeType.logResult,
              position: Offset.zero,
              config: {'message': 'x'}),
        ],
        edges: const [
          RuleEdge(
              id: 'e1',
              sourceNodeId: 'n1',
              sourcePort: 'out',
              targetNodeId: 'n2',
              targetPort: 'in'),
        ],
      ));
      expect(rs().nodes.length, 2);
      expect(rs().edges.length, 1);

      notifier.deleteNode('n2');
      expect(rs().nodes.length, 1);
      expect(rs().nodes.containsKey('n2'), isFalse);
      expect(rs().edges, isEmpty);
    });

    test('deleteNode clears selectedNodeId if deleted node was selected', () {
      final id = notifier.addNode(RuleNodeType.delay, Offset.zero);
      notifier.selectNode(id);
      expect(rs().selectedNodeId, id);

      notifier.deleteNode(id);
      expect(rs().selectedNodeId, isNull);
    });

    test('duplicateNode creates copy with offset position', () {
      final id =
          notifier.addNode(RuleNodeType.sendCommand, const Offset(100, 100));
      notifier.updateNodeConfig(
          id, {'device_id': 'd1', 'command_type': 'on'});

      notifier.duplicateNode(id);
      expect(rs().nodes.length, 2);

      final copy = rs().nodes.values.firstWhere((n) => n.id != id);
      expect(copy.type, RuleNodeType.sendCommand);
      expect(copy.position, const Offset(130, 130));
      expect(copy.config['device_id'], 'd1');
      expect(copy.label, contains('copy'));
    });

    test('selectNode sets selectedNodeId', () {
      final id = notifier.addNode(RuleNodeType.delay, Offset.zero);
      notifier.selectNode(id);
      expect(rs().selectedNodeId, id);

      notifier.selectNode(null);
      expect(rs().selectedNodeId, isNull);
    });

    test('addEdge rejects self-connections', () {
      final id = notifier.addNode(RuleNodeType.manualTrigger, Offset.zero);
      final result = notifier.addEdge(id, 'out', id, 'out');
      expect(result, isNull);
      expect(rs().edges, isEmpty);
    });

    test('addEdge rejects duplicate target port connections', () {
      notifier.loadGraph(RuleGraph(
        nodes: [
          RuleNode(
              id: 'n1',
              type: RuleNodeType.manualTrigger,
              position: Offset.zero),
          RuleNode(
              id: 'n2',
              type: RuleNodeType.greaterThan,
              position: Offset.zero,
              config: {'value': 5}),
          RuleNode(
              id: 'n3',
              type: RuleNodeType.telemetryReceived,
              position: Offset.zero,
              config: {'device_id': 'd1'}),
        ],
      ));

      final first = notifier.addEdge('n1', 'out', 'n2', 'in');
      expect(first, isNotNull);

      final dup = notifier.addEdge('n3', 'out', 'n2', 'in');
      expect(dup, isNull);
    });

    group('undo/redo', () {
      test('add node, undo removes it, redo restores it', () {
        final id = notifier.addNode(RuleNodeType.merge, Offset.zero);
        expect(rs().nodes.containsKey(id), isTrue);

        notifier.undo();
        expect(rs().nodes.containsKey(id), isFalse);
        expect(rs().canRedo, isTrue);

        notifier.redo();
        expect(rs().nodes.containsKey(id), isTrue);
      });

      test('undo on empty stack does nothing', () {
        notifier.undo();
        expect(rs().nodes, isEmpty);
      });

      test('redo on empty stack does nothing', () {
        notifier.redo();
        expect(rs().nodes, isEmpty);
      });
    });

    test('validate populates validationErrors on empty graph', () {
      notifier.validate();
      expect(rs().validationErrors, isNotEmpty);
      expect(rs().validationErrors.first.message,
          contains('at least one trigger'));
    });

    test('clearDirty resets isDirty flag', () {
      notifier.addNode(RuleNodeType.delay, Offset.zero);
      expect(rs().isDirty, isTrue);

      notifier.clearDirty();
      expect(rs().isDirty, isFalse);
    });

    test('startConnection / cancelConnection flow', () {
      notifier.startConnection('n1', 'out');
      expect(rs().pendingConnectionSource, 'n1');
      expect(rs().pendingConnectionPort, 'out');

      notifier.cancelConnection();
      expect(rs().pendingConnectionSource, isNull);
      expect(rs().pendingConnectionPort, isNull);
    });

    test('completeConnection creates edge and clears pending', () {
      notifier.loadGraph(RuleGraph(
        nodes: [
          RuleNode(
              id: 'n1',
              type: RuleNodeType.manualTrigger,
              position: Offset.zero),
          RuleNode(
              id: 'n2',
              type: RuleNodeType.logResult,
              position: Offset.zero,
              config: {'message': 'hi'}),
        ],
      ));

      notifier.startConnection('n1', 'out');
      notifier.completeConnection('n2', 'in');

      expect(rs().edges.length, 1);
      expect(rs().pendingConnectionSource, isNull);
    });

    test('toGraph produces valid RuleGraph', () {
      notifier.addNode(RuleNodeType.manualTrigger, Offset.zero);
      final graph = rs().toGraph();
      expect(graph.nodes.length, 1);
      expect(graph.edges, isEmpty);
    });
  });
}
