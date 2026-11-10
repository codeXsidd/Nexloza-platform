import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_spacing.dart';
import '../../domain/entities/rule_graph.dart';
import '../providers/rule_provider.dart';
import '../widgets/node_catalog_sheet.dart';
import '../widgets/node_config_panel.dart';
import '../widgets/rule_canvas.dart' as canvas;

class RuleEditorScreen extends ConsumerStatefulWidget {
  final String ruleId;

  const RuleEditorScreen({super.key, required this.ruleId});

  @override
  ConsumerState<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends ConsumerState<RuleEditorScreen> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final ruleAsync = ref.watch(ruleDetailProvider(widget.ruleId));
    final editorState = ref.watch(ruleEditorProvider);
    final editorNotifier = ref.read(ruleEditorProvider.notifier);
    final theme = Theme.of(context);

    // Load graph into editor once the rule arrives
    if (!_loaded) {
      ruleAsync.whenData((rule) {
        if (rule != null) {
          _loaded = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            editorNotifier.loadGraph(rule.ruleGraph ?? const RuleGraph());
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rule Editor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _onBack(context, editorState),
        ),
        actions: [
          IconButton(
            onPressed: editorState.canUndo ? editorNotifier.undo : null,
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
          ),
          IconButton(
            onPressed: editorState.canRedo ? editorNotifier.redo : null,
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
          ),
          IconButton(
            onPressed: () => _onValidate(context, editorNotifier, editorState),
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Validate',
          ),
          IconButton(
            onPressed: editorState.isDirty
                ? () => _onSave(context, ref, editorState)
                : null,
            icon: const Icon(Icons.save),
            tooltip: 'Save',
          ),
        ],
      ),
      body: ruleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalSm,
              Text(
                'Failed to load rule',
                style: theme.textTheme.titleMedium,
              ),
              AppSpacing.verticalSm,
              FilledButton(
                onPressed: () =>
                    ref.invalidate(ruleDetailProvider(widget.ruleId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (rule) {
          if (rule == null) {
            return const Center(child: Text('Rule not found'));
          }
          return Column(
            children: [
              // Validation error bar
              if (editorState.validationErrors.isNotEmpty)
                MaterialBanner(
                  content: Text(
                    '${editorState.validationErrors.length} validation '
                    '${editorState.validationErrors.length == 1 ? 'error' : 'errors'}',
                  ),
                  leading: Icon(Icons.warning_amber,
                      color: theme.colorScheme.error),
                  backgroundColor:
                      theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          _showValidationErrors(context, editorState),
                      child: const Text('Details'),
                    ),
                  ],
                ),

              // Canvas
              Expanded(
                child: canvas.RuleCanvas(
                  editorState: canvas.RuleEditorState(
                    nodes: editorState.nodes,
                    edges: editorState.edges,
                    selectedNodeId: editorState.selectedNodeId,
                    validationErrors: editorState.validationErrors,
                  ),
                  onNodeTapped: (nodeId) {
                    editorNotifier.selectNode(nodeId);
                    final node = editorState.nodes[nodeId];
                    if (node != null) {
                      NodeConfigPanel.show(
                        context,
                        node: node,
                        onConfigChanged: (config) =>
                            editorNotifier.updateNodeConfig(nodeId, config),
                        onDelete: () => editorNotifier.deleteNode(nodeId),
                        onLabelChanged: (label) =>
                            editorNotifier.updateNodeLabel(nodeId, label),
                      );
                    }
                  },
                  onNodeMoved: editorNotifier.moveNode,
                  onNodeDeleted: editorNotifier.deleteNode,
                  onEdgeCreated: (src, srcPort, tgt, tgtPort) =>
                      editorNotifier.addEdge(src, srcPort, tgt, tgtPort),
                  onEdgeDeleted: editorNotifier.deleteEdge,
                  onCanvasTapped: () => editorNotifier.selectNode(null),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddNode(context, editorNotifier),
        tooltip: 'Add Node',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _onAddNode(
    BuildContext context,
    RuleEditorNotifier notifier,
  ) async {
    final type = await NodeCatalogSheet.show(context);
    if (type != null) {
      notifier.addNode(type, const Offset(200, 200));
    }
  }

  void _onValidate(
    BuildContext context,
    RuleEditorNotifier notifier,
    RuleEditorState state,
  ) {
    notifier.validate();
    // Read updated state after validation
    final updated = ref.read(ruleEditorProvider);
    if (updated.validationErrors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Graph is valid')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${updated.validationErrors.length} validation '
            '${updated.validationErrors.length == 1 ? 'error' : 'errors'} found',
          ),
        ),
      );
    }
  }

  Future<void> _onSave(
    BuildContext context,
    WidgetRef ref,
    RuleEditorState state,
  ) async {
    final controller = ref.read(ruleControllerProvider);
    final graph = state.toGraph();
    final ok = await controller.saveGraph(widget.ruleId, graph);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Graph saved' : 'Failed to save graph'),
        ),
      );
    }
    if (ok) {
      ref.read(ruleEditorProvider.notifier).clearDirty();
      ref.invalidate(ruleDetailProvider(widget.ruleId));
    }
  }

  void _onBack(BuildContext context, RuleEditorState state) {
    if (state.isDirty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes. Discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _showValidationErrors(BuildContext context, RuleEditorState state) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validation Errors',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppSpacing.verticalSm,
            for (final error in state.validationErrors)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.error, color: Colors.red, size: 20),
                title: Text(error.message),
                subtitle: error.nodeId != null
                    ? Text('Node: ${error.nodeId}')
                    : null,
              ),
            AppSpacing.verticalMd,
          ],
        ),
      ),
    );
  }
}

