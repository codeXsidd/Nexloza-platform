import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_spacing.dart';
import '../../data/dashboard_repository.dart';
import '../../data/telemetry_data_service.dart';
import '../../domain/entities/dashboard_widget_entity.dart';
import '../../domain/entities/data_source.dart';
import '../../domain/entities/widget_type.dart';
import '../../domain/widget_registry.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/data_source_selector.dart';
import '../widgets/widget_catalog_sheet.dart';

class DashboardEditorScreen extends ConsumerStatefulWidget {
  final String dashboardId;

  const DashboardEditorScreen({super.key, required this.dashboardId});

  @override
  ConsumerState<DashboardEditorScreen> createState() =>
      _DashboardEditorScreenState();
}

class _DashboardEditorScreenState extends ConsumerState<DashboardEditorScreen> {
  bool _isEditing = false;
  bool _isFullScreen = false;

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(
      dashboardDetailProvider(widget.dashboardId),
    );
    final widgetsAsync = ref.watch(
      dashboardWidgetsProvider(widget.dashboardId),
    );

    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: dashboardAsync.when(
                loading: () => const Text('Dashboard'),
                error: (_, __) => const Text('Dashboard'),
                data: (d) => Text(d?.name ?? 'Dashboard'),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  tooltip: 'Full screen',
                  onPressed: () => setState(() => _isFullScreen = true),
                ),
                IconButton(
                  icon: Icon(_isEditing ? Icons.check : Icons.edit),
                  tooltip: _isEditing ? 'Done editing' : 'Edit layout',
                  onPressed: () => setState(() => _isEditing = !_isEditing),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => _handleMenuAction(v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Duplicate'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: ListTile(
                        leading: Icon(Icons.file_download),
                        title: Text('Export JSON'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Rename'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              onPressed: () => _showWidgetCatalog(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: Stack(
        children: [
          widgetsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (widgets) {
              if (widgets.isEmpty) {
                return _EmptyDashboard(
                  onAdd: () {
                    setState(() => _isEditing = true);
                    _showWidgetCatalog(context);
                  },
                );
              }
              return _DashboardGrid(
                widgets: widgets,
                isEditing: _isEditing,
                dashboardId: widget.dashboardId,
                onConfigure: _showWidgetConfig,
                onDelete: _deleteWidget,
              );
            },
          ),
          if (_isFullScreen)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 8,
              child: IconButton.filled(
                icon: const Icon(Icons.fullscreen_exit),
                onPressed: () => setState(() => _isFullScreen = false),
              ),
            ),
        ],
      ),
    );
  }

  void _showWidgetCatalog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => WidgetCatalogSheet(onSelect: (type) => _addWidget(type)),
    );
  }

  Future<void> _addWidget(NexWidgetType type) async {
    final repo = ref.read(dashboardRepositoryProvider);
    final widgets =
        ref.read(dashboardWidgetsProvider(widget.dashboardId)).valueOrNull ??
        [];
    await repo.addWidget(
      dashboardId: widget.dashboardId,
      widgetType: type.typeId,
      title: type.displayName,
      gridW: type.defaultWidth,
      gridH: type.defaultHeight,
      sortOrder: widgets.length,
    );
    ref.invalidate(dashboardWidgetsProvider(widget.dashboardId));
  }

  Future<void> _deleteWidget(DashboardWidget w) async {
    final repo = ref.read(dashboardRepositoryProvider);
    await repo.deleteWidget(w.id);
    ref.invalidate(dashboardWidgetsProvider(widget.dashboardId));
  }

  void _showWidgetConfig(DashboardWidget w) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _WidgetConfigSheet(
        widget: w,
        onSave: (updates) async {
          final repo = ref.read(dashboardRepositoryProvider);
          await repo.updateWidget(w.id, updates);
          ref.invalidate(dashboardWidgetsProvider(widget.dashboardId));
        },
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'duplicate':
        final result = await ref
            .read(dashboardsProvider.notifier)
            .duplicateDashboard(widget.dashboardId);
        if (mounted && result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Duplicated as "${result.name}"')),
          );
        }
      case 'export':
        await _exportDashboard();
      case 'rename':
        await _renameDashboard();
    }
  }

  Future<void> _exportDashboard() async {
    final repo = ref.read(dashboardRepositoryProvider);
    final dashResult = await repo.getDashboard(widget.dashboardId);
    final widgetsResult = await repo.getWidgets(widget.dashboardId);

    dashResult.when(
      success: (dashboard) {
        widgetsResult.when(
          success: (widgets) {
            final json = repo.exportDashboardJson(dashboard, widgets);
            if (mounted) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Export JSON'),
                  content: SingleChildScrollView(
                    child: SelectableText(
                      json,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
          },
          failure: (_) {},
        );
      },
      failure: (_) {},
    );
  }

  Future<void> _renameDashboard() async {
    final dashboard = ref
        .read(dashboardDetailProvider(widget.dashboardId))
        .valueOrNull;
    if (dashboard == null) return;
    final ctl = TextEditingController(text: dashboard.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Dashboard'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await ref.read(dashboardsProvider.notifier).updateDashboard(
        widget.dashboardId,
        {'name': newName},
      );
      ref.invalidate(dashboardDetailProvider(widget.dashboardId));
    }
  }
}

class _EmptyDashboard extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyDashboard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.widgets_outlined,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          AppSpacing.verticalMd,
          Text('No widgets yet', style: theme.textTheme.titleMedium),
          AppSpacing.verticalSm,
          Text(
            'Add widgets to build your dashboard',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalLg,
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Widget'),
          ),
        ],
      ),
    );
  }
}

class _DashboardGrid extends ConsumerWidget {
  final List<DashboardWidget> widgets;
  final bool isEditing;
  final String dashboardId;
  final void Function(DashboardWidget) onConfigure;
  final void Function(DashboardWidget) onDelete;

  const _DashboardGrid({
    required this.widgets,
    required this.isEditing,
    required this.dashboardId,
    required this.onConfigure,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = WidgetRegistry();
    final telemetryService = ref.watch(telemetryDataServiceProvider);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900 ? 4 : (width >= 600 ? 3 : 2);

    if (isEditing) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: widgets.length,
        onReorderItem: (oldIndex, newIndex) async {
          final ids = widgets.map((w) => w.id).toList();
          final id = ids.removeAt(oldIndex);
          ids.insert(newIndex, id);
          final repo = ref.read(dashboardRepositoryProvider);
          await repo.reorderWidgets(dashboardId, ids);
          ref.invalidate(dashboardWidgetsProvider(dashboardId));
        },
        itemBuilder: (context, index) {
          final w = widgets[index];
          return Card(
            key: ValueKey(w.id),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(w.widgetType.icon),
              title: Text(w.title),
              subtitle: Text(w.widgetType.displayName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 20),
                    onPressed: () => onConfigure(w),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => onDelete(w),
                  ),
                  const Icon(Icons.drag_handle),
                ],
              ),
            ),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(dashboardWidgetsProvider(dashboardId)),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: widgets.length,
        itemBuilder: (context, index) {
          final w = widgets[index];
          final data = _buildDataState(w, telemetryService);
          return GestureDetector(
            onLongPress: () => onConfigure(w),
            child: registry.build(context, w, data),
          );
        },
      ),
    );
  }

  WidgetDataState _buildDataState(
    DashboardWidget w,
    TelemetryDataService service,
  ) {
    final ds = w.dataSource;
    if (!ds.isBound) {
      final staticVal = w.config['value'];
      return WidgetDataState(currentValue: staticVal);
    }

    final latest = service.getLatest(ds.deviceId!, ds.effectiveKey);
    if (latest != null) {
      return WidgetDataState(
        currentValue:
            latest.valueNumeric ?? latest.valueText ?? latest.valueJson,
      );
    }

    return const WidgetDataState(isLoading: true);
  }
}

class _WidgetConfigSheet extends StatefulWidget {
  final DashboardWidget widget;
  final Future<void> Function(Map<String, dynamic> updates) onSave;

  const _WidgetConfigSheet({required this.widget, required this.onSave});

  @override
  State<_WidgetConfigSheet> createState() => _WidgetConfigSheetState();
}

class _WidgetConfigSheetState extends State<_WidgetConfigSheet> {
  late TextEditingController _titleCtl;
  late TextEditingController _unitCtl;
  late TextEditingController _minCtl;
  late TextEditingController _maxCtl;
  DataSource _dataSource = const DataSource();

  @override
  void initState() {
    super.initState();
    _titleCtl = TextEditingController(text: widget.widget.title);
    _unitCtl = TextEditingController(text: widget.widget.unit);
    _minCtl = TextEditingController(text: widget.widget.rangeMin.toString());
    _maxCtl = TextEditingController(text: widget.widget.rangeMax.toString());
    _dataSource = widget.widget.dataSource;
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _unitCtl.dispose();
    _minCtl.dispose();
    _maxCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.widget.widgetType.icon),
                const SizedBox(width: 8),
                Text('Configure Widget', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            Text('Data Source', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DataSourceSelector(
              dataSource: _dataSource,
              onChanged: (ds) => setState(() => _dataSource = ds),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _unitCtl,
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _minCtl,
                    decoration: const InputDecoration(labelText: 'Min'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxCtl,
                    decoration: const InputDecoration(labelText: 'Max'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final config = Map<String, dynamic>.from(widget.widget.config);
    config['data_source'] = _dataSource.toJson();
    config['display'] = {
      ...widget.widget.displayConfig,
      'unit': _unitCtl.text.trim(),
    };
    final min = double.tryParse(_minCtl.text);
    final max = double.tryParse(_maxCtl.text);
    if (min != null || max != null) {
      config['range'] = {
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      };
    }

    widget.onSave({'title': _titleCtl.text.trim(), 'config': config});
    Navigator.pop(context);
  }
}
