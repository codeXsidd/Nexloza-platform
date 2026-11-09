import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_spacing.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/entities/dashboard_widget_entity.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/gauge_widget_card.dart';
import '../widgets/value_display_widget_card.dart';
import '../widgets/toggle_widget_card.dart';
import '../widgets/status_indicator_widget_card.dart';
import '../widgets/chart_widget_card.dart';

class DashboardEditorScreen extends ConsumerStatefulWidget {
  final String dashboardId;

  const DashboardEditorScreen({super.key, required this.dashboardId});

  @override
  ConsumerState<DashboardEditorScreen> createState() =>
      _DashboardEditorScreenState();
}

class _DashboardEditorScreenState extends ConsumerState<DashboardEditorScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final widgetsAsync = ref.watch(
      dashboardWidgetsProvider(widget.dashboardId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            tooltip: _isEditing ? 'Done editing' : 'Edit layout',
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Widget',
              onPressed: () => _showAddWidgetSheet(context),
            ),
        ],
      ),
      body: widgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (widgets) {
          if (widgets.isEmpty) {
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
                    'Tap Edit then Add to create your first widget.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.verticalLg,
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _isEditing = true);
                      _showAddWidgetSheet(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Widget'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(dashboardWidgetsProvider(widget.dashboardId)),
            child: GridView.builder(
              padding: AppSpacing.screenPadding,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: widgets.length,
              itemBuilder: (context, index) {
                final w = widgets[index];
                return _buildWidgetCard(context, w);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWidgetCard(BuildContext context, DashboardWidget w) {
    final card = switch (w.widgetType) {
      DashboardWidgetType.gauge => GaugeWidgetCard(widget: w),
      DashboardWidgetType.valueDisplay => ValueDisplayWidgetCard(widget: w),
      DashboardWidgetType.toggle => ToggleWidgetCard(widget: w),
      DashboardWidgetType.statusIndicator => StatusIndicatorWidgetCard(
        widget: w,
      ),
      DashboardWidgetType.lineChart => ChartWidgetCard(widget: w),
      DashboardWidgetType.barChart => ChartWidgetCard(widget: w),
      DashboardWidgetType.map => _PlaceholderWidgetCard(widget: w),
    };

    if (!_isEditing) return card;

    return Stack(
      children: [
        card,
        Positioned(
          top: 4,
          right: 4,
          child: CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.error,
            child: IconButton(
              iconSize: 14,
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () async {
                final repo = ref.read(dashboardRepositoryProvider);
                await repo.deleteWidget(w.id);
                ref.invalidate(dashboardWidgetsProvider(widget.dashboardId));
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showAddWidgetSheet(BuildContext context) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    DashboardWidgetType selectedType = DashboardWidgetType.valueDisplay;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Widget', style: theme.textTheme.titleLarge),
              AppSpacing.verticalMd,
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Widget Title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              AppSpacing.verticalMd,
              DropdownButtonFormField<DashboardWidgetType>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Widget Type',
                  prefixIcon: Icon(Icons.widgets),
                ),
                items: DashboardWidgetType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSheetState(
                  () => selectedType = v ?? DashboardWidgetType.valueDisplay,
                ),
              ),
              AppSpacing.verticalLg,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final title = nameController.text.trim();
                    if (title.isEmpty) return;
                    Navigator.pop(ctx);
                    final repo = ref.read(dashboardRepositoryProvider);
                    await repo.addWidget(
                      dashboardId: widget.dashboardId,
                      widgetType: selectedType,
                      title: title,
                    );
                    ref.invalidate(
                      dashboardWidgetsProvider(widget.dashboardId),
                    );
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderWidgetCard extends StatelessWidget {
  final DashboardWidget widget;

  const _PlaceholderWidgetCard({required this.widget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: theme.textTheme.titleSmall),
            const Spacer(),
            Center(
              child: Icon(
                Icons.map_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
            ),
            const Spacer(),
            Text(
              widget.widgetType.displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
