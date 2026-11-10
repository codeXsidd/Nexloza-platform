import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/rule_repository.dart';
import '../../data/rule_execution_repository.dart';
import '../../data/rule_event_service.dart';
import '../../domain/entities/rule_graph.dart';
import '../../domain/entities/rule_execution.dart';
import '../../domain/entities/rule_node_type.dart';
import '../../domain/entities/rule_validation.dart';

// ---------------------------------------------------------------------------
// Rule list
// ---------------------------------------------------------------------------

final rulesProvider =
    FutureProvider.family<List<RuleAutomation>, String?>((ref, projectId) async {
  final repo = ref.watch(ruleRepositoryProvider);
  final result = await repo.getRules(projectId: projectId);
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

// ---------------------------------------------------------------------------
// Single rule detail
// ---------------------------------------------------------------------------

final ruleDetailProvider =
    FutureProvider.family<RuleAutomation?, String>((ref, id) async {
  final repo = ref.watch(ruleRepositoryProvider);
  final result = await repo.getRule(id);
  return result.when(
    success: (data) => data,
    failure: (_) => null,
  );
});

// ---------------------------------------------------------------------------
// Version history
// ---------------------------------------------------------------------------

final ruleVersionsProvider =
    FutureProvider.family<List<RuleVersion>, String>((ref, automationId) async {
  final repo = ref.watch(ruleRepositoryProvider);
  final result = await repo.getVersionHistory(automationId);
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

// ---------------------------------------------------------------------------
// Execution history
// ---------------------------------------------------------------------------

final ruleExecutionsProvider =
    FutureProvider.family<List<RuleExecution>, String>(
        (ref, automationId) async {
  final repo = ref.watch(ruleExecutionRepositoryProvider);
  final result = await repo.getExecutions(automationId: automationId);
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});

final executionDetailProvider =
    FutureProvider.family<RuleExecution?, String>((ref, executionId) async {
  final repo = ref.watch(ruleExecutionRepositoryProvider);
  final result = await repo.getExecution(executionId);
  return result.when(
    success: (data) => data,
    failure: (_) => null,
  );
});

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

final ruleValidationProvider = FutureProvider.family<List<ValidationError>,
    String>((ref, automationId) async {
  final repo = ref.watch(ruleRepositoryProvider);
  final result = await repo.getRule(automationId);
  return result.when(
    success: (automation) {
      final graph = automation.ruleGraph;
      if (graph == null) {
        return [const ValidationError(message: 'No rule graph defined')];
      }
      return const RuleGraphValidator().validate(graph);
    },
    failure: (f) => [ValidationError(message: f.message)],
  );
});

// ---------------------------------------------------------------------------
// Editor state
// ---------------------------------------------------------------------------

class UndoEntry {
  final Map<String, RuleNode> nodes;
  final Map<String, RuleEdge> edges;

  const UndoEntry({required this.nodes, required this.edges});
}

class RuleEditorState {
  final Map<String, RuleNode> nodes;
  final Map<String, RuleEdge> edges;
  final String? selectedNodeId;
  final String? pendingConnectionSource;
  final String? pendingConnectionPort;
  final List<UndoEntry> undoStack;
  final List<UndoEntry> redoStack;
  final List<ValidationError> validationErrors;
  final bool isDirty;

  const RuleEditorState({
    this.nodes = const {},
    this.edges = const {},
    this.selectedNodeId,
    this.pendingConnectionSource,
    this.pendingConnectionPort,
    this.undoStack = const [],
    this.redoStack = const [],
    this.validationErrors = const [],
    this.isDirty = false,
  });

  RuleEditorState copyWith({
    Map<String, RuleNode>? nodes,
    Map<String, RuleEdge>? edges,
    String? Function()? selectedNodeId,
    String? Function()? pendingConnectionSource,
    String? Function()? pendingConnectionPort,
    List<UndoEntry>? undoStack,
    List<UndoEntry>? redoStack,
    List<ValidationError>? validationErrors,
    bool? isDirty,
  }) {
    return RuleEditorState(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      selectedNodeId:
          selectedNodeId != null ? selectedNodeId() : this.selectedNodeId,
      pendingConnectionSource: pendingConnectionSource != null
          ? pendingConnectionSource()
          : this.pendingConnectionSource,
      pendingConnectionPort: pendingConnectionPort != null
          ? pendingConnectionPort()
          : this.pendingConnectionPort,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      validationErrors: validationErrors ?? this.validationErrors,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  RuleGraph toGraph() => RuleGraph(
        nodes: nodes.values.toList(),
        edges: edges.values.toList(),
      );

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
}

class RuleEditorNotifier extends Notifier<RuleEditorState> {
  int _nodeCounter = 0;
  int _edgeCounter = 0;

  @override
  RuleEditorState build() => const RuleEditorState();

  void loadGraph(RuleGraph graph) {
    final nodes = <String, RuleNode>{};
    for (final n in graph.nodes) {
      nodes[n.id] = n;
    }
    final edges = <String, RuleEdge>{};
    for (final e in graph.edges) {
      edges[e.id] = e;
    }
    _nodeCounter = graph.nodes.length;
    _edgeCounter = graph.edges.length;
    state = RuleEditorState(nodes: nodes, edges: edges);
  }

  void _pushUndo() {
    final entry = UndoEntry(
      nodes: Map.of(state.nodes),
      edges: Map.of(state.edges),
    );
    state = state.copyWith(
      undoStack: [...state.undoStack, entry],
      redoStack: const [],
      isDirty: true,
    );
  }

  void undo() {
    if (!state.canUndo) return;
    final entry = state.undoStack.last;
    final redo = UndoEntry(
      nodes: Map.of(state.nodes),
      edges: Map.of(state.edges),
    );
    state = state.copyWith(
      nodes: Map.of(entry.nodes),
      edges: Map.of(entry.edges),
      undoStack: state.undoStack.sublist(0, state.undoStack.length - 1),
      redoStack: [...state.redoStack, redo],
      isDirty: true,
    );
  }

  void redo() {
    if (!state.canRedo) return;
    final entry = state.redoStack.last;
    final undo = UndoEntry(
      nodes: Map.of(state.nodes),
      edges: Map.of(state.edges),
    );
    state = state.copyWith(
      nodes: Map.of(entry.nodes),
      edges: Map.of(entry.edges),
      undoStack: [...state.undoStack, undo],
      redoStack: state.redoStack.sublist(0, state.redoStack.length - 1),
      isDirty: true,
    );
  }

  String addNode(RuleNodeType type, Offset position) {
    _pushUndo();
    final id = 'node_${++_nodeCounter}';
    final node = RuleNode(
      id: id,
      type: type,
      position: position,
      label: type.displayName,
    );
    state = state.copyWith(
      nodes: {...state.nodes, id: node},
    );
    return id;
  }

  void moveNode(String nodeId, Offset delta) {
    final node = state.nodes[nodeId];
    if (node == null) return;
    final updated = node.copyWith(position: node.position + delta);
    state = state.copyWith(
      nodes: {...state.nodes, nodeId: updated},
      isDirty: true,
    );
  }

  void updateNodeConfig(String nodeId, Map<String, dynamic> config) {
    _pushUndo();
    final node = state.nodes[nodeId];
    if (node == null) return;
    final updated = node.copyWith(config: config);
    state = state.copyWith(
      nodes: {...state.nodes, nodeId: updated},
    );
  }

  void updateNodeLabel(String nodeId, String label) {
    _pushUndo();
    final node = state.nodes[nodeId];
    if (node == null) return;
    final updated = node.copyWith(label: label);
    state = state.copyWith(
      nodes: {...state.nodes, nodeId: updated},
    );
  }

  void deleteNode(String nodeId) {
    _pushUndo();
    final nodes = Map.of(state.nodes)..remove(nodeId);
    final edges = Map.of(state.edges)
      ..removeWhere(
          (_, e) => e.sourceNodeId == nodeId || e.targetNodeId == nodeId);
    state = state.copyWith(
      nodes: nodes,
      edges: edges,
      selectedNodeId: () =>
          state.selectedNodeId == nodeId ? null : state.selectedNodeId,
    );
  }

  void duplicateNode(String nodeId) {
    final node = state.nodes[nodeId];
    if (node == null) return;
    _pushUndo();
    final newId = 'node_${++_nodeCounter}';
    final newNode = RuleNode(
      id: newId,
      type: node.type,
      position: node.position + const Offset(30, 30),
      config: Map.of(node.config),
      label: '${node.label} (copy)',
    );
    state = state.copyWith(
      nodes: {...state.nodes, newId: newNode},
    );
  }

  void selectNode(String? nodeId) {
    state = state.copyWith(selectedNodeId: () => nodeId);
  }

  String? addEdge(
    String sourceNodeId,
    String sourcePort,
    String targetNodeId,
    String targetPort,
  ) {
    if (sourceNodeId == targetNodeId) return null;

    final existing = state.edges.values.any(
        (e) => e.targetNodeId == targetNodeId && e.targetPort == targetPort);
    if (existing) return null;

    _pushUndo();
    final id = 'edge_${++_edgeCounter}';
    final edge = RuleEdge(
      id: id,
      sourceNodeId: sourceNodeId,
      sourcePort: sourcePort,
      targetNodeId: targetNodeId,
      targetPort: targetPort,
    );
    state = state.copyWith(
      edges: {...state.edges, id: edge},
    );
    return id;
  }

  void deleteEdge(String edgeId) {
    _pushUndo();
    final edges = Map.of(state.edges)..remove(edgeId);
    state = state.copyWith(edges: edges);
  }

  void startConnection(String nodeId, String portId) {
    state = state.copyWith(
      pendingConnectionSource: () => nodeId,
      pendingConnectionPort: () => portId,
    );
  }

  void cancelConnection() {
    state = state.copyWith(
      pendingConnectionSource: () => null,
      pendingConnectionPort: () => null,
    );
  }

  void completeConnection(String targetNodeId, String targetPortId) {
    final source = state.pendingConnectionSource;
    final port = state.pendingConnectionPort;
    if (source != null && port != null) {
      addEdge(source, port, targetNodeId, targetPortId);
    }
    cancelConnection();
  }

  void validate() {
    final graph = state.toGraph();
    final errors = const RuleGraphValidator().validate(graph);
    state = state.copyWith(validationErrors: errors);
  }

  void clearDirty() {
    state = state.copyWith(isDirty: false);
  }
}

final ruleEditorProvider =
    NotifierProvider<RuleEditorNotifier, RuleEditorState>(
  RuleEditorNotifier.new,
);

// ---------------------------------------------------------------------------
// Rule Controller
// ---------------------------------------------------------------------------

class RuleController {
  final RuleRepository _repo;
  final RuleEventService _eventService;

  RuleController(this._repo, this._eventService);

  Future<bool> saveGraph(String automationId, RuleGraph graph) async {
    final result = await _repo.saveGraph(automationId, graph);
    return result.when(success: (_) => true, failure: (_) => false);
  }

  Future<List<ValidationError>> validateRule(String automationId) async {
    final result = await _repo.validateRule(automationId);
    return result.when(
      success: (errors) => errors,
      failure: (f) => [ValidationError(message: f.message)],
    );
  }

  Future<bool> publishRule(String automationId) async {
    final result = await _repo.publishRule(automationId);
    return result.when(success: (_) => true, failure: (_) => false);
  }

  Future<bool> enableRule(String id) async {
    final result = await _repo.enableRule(id);
    return result.when(success: (_) => true, failure: (_) => false);
  }

  Future<bool> disableRule(String id) async {
    final result = await _repo.disableRule(id);
    return result.when(success: (_) => true, failure: (_) => false);
  }

  Future<bool> archiveRule(String id) async {
    final result = await _repo.archiveRule(id);
    return result.when(success: (_) => true, failure: (_) => false);
  }

  Future<bool> deleteRule(String id) async {
    final result = await _repo.deleteRule(id);
    return result.when(success: (_) => true, failure: (_) => false);
  }

  Future<bool> submitDryRun({
    required String automationId,
    required String eventType,
    String? deviceId,
    required String projectId,
    required String organizationId,
    Map<String, dynamic> payload = const {},
  }) async {
    final result = await _eventService.submitDryRun(
      automationId: automationId,
      eventType: eventType,
      deviceId: deviceId,
      projectId: projectId,
      organizationId: organizationId,
      payload: payload,
    );
    return result.when(success: (_) => true, failure: (_) => false);
  }
}

final ruleControllerProvider = Provider<RuleController>((ref) {
  return RuleController(
    ref.watch(ruleRepositoryProvider),
    ref.watch(ruleEventServiceProvider),
  );
});
