import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../providers/dashboard_provider.dart';

class DashboardsScreen extends ConsumerStatefulWidget {
  const DashboardsScreen({super.key});

  @override
  ConsumerState<DashboardsScreen> createState() => _DashboardsScreenState();
}

class _DashboardsScreenState extends ConsumerState<DashboardsScreen> {
  String _search = '';
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dashboardsAsync = ref.watch(dashboardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboards'),
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.archive : Icons.archive_outlined),
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_upload),
                  title: Text('Import JSON'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search dashboards...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: dashboardsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    AppSpacing.verticalSm,
                    Text(
                      'Failed to load dashboards',
                      style: theme.textTheme.titleMedium,
                    ),
                    AppSpacing.verticalSm,
                    FilledButton(
                      onPressed: () => ref.invalidate(dashboardsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (dashboards) {
                var filtered = dashboards.where((d) {
                  if (!_showArchived && d.isArchived) return false;
                  if (_search.isNotEmpty) {
                    final q = _search.toLowerCase();
                    return d.name.toLowerCase().contains(q) ||
                        (d.description?.toLowerCase().contains(q) ?? false);
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  if (_search.isNotEmpty) {
                    return Center(
                      child: Text(
                        'No dashboards matching "$_search"',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }
                  return EmptyStateWidget(
                    icon: Icons.dashboard_outlined,
                    title: 'No Dashboards',
                    subtitle:
                        'Create a custom dashboard to monitor your devices.',
                    actionLabel: 'Create Dashboard',
                    onAction: () =>
                        context.pushNamed(RouteNames.createDashboard),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(dashboardsProvider),
                  child: ListView.separated(
                    padding: AppSpacing.screenPadding,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => AppSpacing.verticalSm,
                    itemBuilder: (context, index) =>
                        _DashboardCard(dashboard: filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.createDashboard),
        icon: const Icon(Icons.add),
        label: const Text('New Dashboard'),
      ),
    );
  }

  void _handleMenuAction(String action) {
    if (action == 'import') {
      _showImportDialog();
    }
  }

  void _showImportDialog() {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Dashboard JSON'),
        content: TextField(
          controller: ctl,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste exported dashboard JSON here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              if (ctl.text.trim().isEmpty) return;
              final repo = ref.read(dashboardRepositoryProvider);
              final result = await repo.importDashboardJson(
                '',
                ctl.text.trim(),
              );
              result.when(
                success: (_) {
                  ref.invalidate(dashboardsProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dashboard imported')),
                    );
                  }
                },
                failure: (f) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Import failed: ${f.message}')),
                    );
                  }
                },
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends ConsumerWidget {
  final Dashboard dashboard;

  const _DashboardCard({required this.dashboard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.dashboardEditor,
          pathParameters: {'id': dashboard.id},
        ),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: dashboard.isArchived
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  dashboard.isArchived ? Icons.archive : Icons.dashboard,
                  color: dashboard.isArchived
                      ? theme.colorScheme.outline
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dashboard.name,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (dashboard.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Default',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (dashboard.description != null &&
                        dashboard.description!.isNotEmpty)
                      Text(
                        dashboard.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                onPressed: () async {
                  final confirmed = await showConfirmationDialog(
                    context,
                    title: 'Delete Dashboard',
                    message:
                        'Delete "${dashboard.name}"? This removes all widgets.',
                    confirmLabel: 'Delete',
                    isDestructive: true,
                  );
                  if (confirmed) {
                    ref
                        .read(dashboardsProvider.notifier)
                        .deleteDashboard(dashboard.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
