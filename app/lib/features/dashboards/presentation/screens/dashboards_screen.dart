import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../providers/dashboard_provider.dart';

class DashboardsScreen extends ConsumerWidget {
  const DashboardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardsAsync = ref.watch(dashboardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboards')),
      body: dashboardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalSm,
              Text(
                'Failed to load dashboards',
                style: Theme.of(context).textTheme.titleMedium,
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
          if (dashboards.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.dashboard_outlined,
              title: 'No Dashboards',
              subtitle: 'Create a custom dashboard to monitor your devices.',
              actionLabel: 'Create Dashboard',
              onAction: () => context.pushNamed(RouteNames.createDashboard),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dashboardsProvider),
            child: ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: dashboards.length,
              separatorBuilder: (_, __) => AppSpacing.verticalSm,
              itemBuilder: (context, index) =>
                  _DashboardCard(dashboard: dashboards[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.createDashboard),
        icon: const Icon(Icons.add),
        label: const Text('New Dashboard'),
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
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard,
                  color: theme.colorScheme.onPrimaryContainer,
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
