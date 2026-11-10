import 'package:flutter/material.dart';

import '../../domain/entities/rule_graph.dart';
import '../../domain/entities/rule_validation.dart';
import 'edge_painter.dart';
import 'node_widget.dart';

class RuleEditorState {
  final Map<String, RuleNode> nodes;
  final Map<String, RuleEdge> edges;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final List<ValidationError> validationErrors;

  const RuleEditorState({
    this.nodes = const {},
    this.edges = const {},
    this.selectedNodeId,
    this.selectedEdgeId,
    this.validationErrors = const [],
  });
}

class PendingConnection {
  final String sourceNodeId;
  final String sourcePort;
  final bool isOutput;
  final Offset startPosition;

  const PendingConnection({
    required this.sourceNodeId,
    required this.sourcePort,
    required this.isOutput,
    required this.startPosition,
  });
}

class RuleCanvas extends StatefulWidget {
  final RuleEditorState editorState;
  final ValueChanged<String>? onNodeTapped;
  final void Function(String nodeId, Offset delta)? onNodeMoved;
  final ValueChanged<String>? onNodeDeleted;
  final void Function(
    String sourceNodeId,
    String sourcePort,
    String targetNodeId,
    String targetPort,
  )?
  onEdgeCreated;
  final ValueChanged<String>? onEdgeDeleted;
  final VoidCallback? onCanvasTapped;

  const RuleCanvas({
    super.key,
    required this.editorState,
    this.onNodeTapped,
    this.onNodeMoved,
    this.onNodeDeleted,
    this.onEdgeCreated,
    this.onEdgeDeleted,
    this.onCanvasTapped,
  });

  @override
  State<RuleCanvas> createState() => _RuleCanvasState();
}

class _RuleCanvasState extends State<RuleCanvas> {
  PendingConnection? _pending;
  Offset _pendingEnd = Offset.zero;
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Set<String> _nodeIdsWithErrors() {
    final ids = <String>{};
    for (final err in widget.editorState.validationErrors) {
      if (err.nodeId != null) ids.add(err.nodeId!);
    }
    return ids;
  }

  void _onPortTapDown(String nodeId, String portId, bool isOutput) {
    if (!isOutput) return;
    final node = widget.editorState.nodes[nodeId];
    if (node == null) return;
    final portIndex = node.type.outputPorts.indexWhere((p) => p.id == portId);
    if (portIndex < 0) return;
    final pos = Offset(
      node.position.dx + NodeWidget.width,
      node.position.dy +
          NodeWidget.headerHeight +
          12 +
          portIndex * NodeWidget.portSpacing,
    );
    setState(() {
      _pending = PendingConnection(
        sourceNodeId: nodeId,
        sourcePort: portId,
        isOutput: true,
        startPosition: pos,
      );
      _pendingEnd = pos;
    });
  }

  void _onPortTapUp(String nodeId, String portId, bool isOutput) {
    if (_pending == null || isOutput) {
      setState(() => _pending = null);
      return;
    }
    if (_pending!.sourceNodeId == nodeId) {
      setState(() => _pending = null);
      return;
    }
    widget.onEdgeCreated?.call(
      _pending!.sourceNodeId,
      _pending!.sourcePort,
      nodeId,
      portId,
    );
    setState(() => _pending = null);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.editorState;
    final errorNodeIds = _nodeIdsWithErrors();

    return GestureDetector(
      onTap: () {
        setState(() => _pending = null);
        widget.onCanvasTapped?.call();
      },
      onPanUpdate: _pending != null
          ? (d) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox == null) return;
              final inv = Matrix4.inverted(_transformController.value);
              final local = MatrixUtils.transformPoint(
                inv,
                renderBox.globalToLocal(d.globalPosition),
              );
              setState(() => _pendingEnd = local);
            }
          : null,
      onPanEnd: _pending != null
          ? (_) => setState(() => _pending = null)
          : null,
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: 0.3,
        maxScale: 3.0,
        boundaryMargin: const EdgeInsets.all(500),
        constrained: false,
        child: SizedBox(
          width: 4000,
          height: 4000,
          child: Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: GridPainter())),
              Positioned.fill(
                child: CustomPaint(
                  painter: EdgePainter(
                    edges: state.edges.values.toList(),
                    nodes: state.nodes,
                    selectedEdgeId: state.selectedEdgeId,
                    pendingStart: _pending?.startPosition,
                    pendingEnd: _pending != null ? _pendingEnd : null,
                    pendingColor: _pending != null
                        ? (state
                                  .nodes[_pending!.sourceNodeId]
                                  ?.type
                                  .category
                                  .color ??
                              Colors.grey)
                        : Colors.grey,
                  ),
                ),
              ),
              for (final node in state.nodes.values)
                Positioned(
                  left: node.position.dx,
                  top: node.position.dy,
                  child: NodeWidget(
                    node: node,
                    isSelected: node.id == state.selectedNodeId,
                    hasError: errorNodeIds.contains(node.id),
                    onTap: () => widget.onNodeTapped?.call(node.id),
                    onMoved: (delta) =>
                        widget.onNodeMoved?.call(node.id, delta),
                    onDelete: () => widget.onNodeDeleted?.call(node.id),
                    onPortTapDown: _onPortTapDown,
                    onPortTapUp: _onPortTapUp,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
