import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../data/alarm_config_repository.dart';
import '../../domain/entities/alarm_configuration_entity.dart';
import '../providers/alarm_providers.dart';

class AlarmConfigScreen extends ConsumerWidget {
  final String projectId;

  const AlarmConfigScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(alarmConfigsProvider(projectId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Alarm Configurations')),
      body: configsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalSm,
              Text(
                'Failed to load configurations',
                style: theme.textTheme.titleMedium,
              ),
              AppSpacing.verticalSm,
              FilledButton(
                onPressed: () =>
                    ref.invalidate(alarmConfigsProvider(projectId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (configs) {
          if (configs.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.settings_suggest,
              title: 'No Alarm Configurations',
              subtitle:
                  'Create alarm configurations to automatically detect issues.',
              actionLabel: 'Create Configuration',
              onAction: () => context.pushNamed(
                RouteNames.createAlarmConfig,
                queryParameters: {'projectId': projectId},
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(alarmConfigsProvider(projectId)),
            child: ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: configs.length,
              separatorBuilder: (_, __) => AppSpacing.verticalSm,
              itemBuilder: (context, index) {
                final config = configs[index];
                return _ConfigCard(
                  config: config,
                  onToggle: (enabled) {
                    ref
                        .read(alarmConfigRepositoryProvider)
                        .toggleConfiguration(config.id, enabled);
                    ref.invalidate(alarmConfigsProvider(projectId));
                  },
                  onDelete: () async {
                    final confirmed = await showConfirmationDialog(
                      context,
                      title: 'Delete Configuration',
                      message:
                          'Are you sure you want to delete "${config.name}"?',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                    if (confirmed) {
                      await ref
                          .read(alarmConfigRepositoryProvider)
                          .deleteConfiguration(config.id);
                      ref.invalidate(alarmConfigsProvider(projectId));
                    }
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(
          RouteNames.createAlarmConfig,
          queryParameters: {'projectId': projectId},
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Config'),
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final AlarmConfiguration config;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _ConfigCard({
    required this.config,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(config.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Icon(
                config.source.icon,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              AppSpacing.horizontalSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(config.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: config.severity.color.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            config.severity.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: config.severity.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (config.thresholdValue != null)
                          Text(
                            '${config.operatorDisplayName} ${config.thresholdValue}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        if (config.hysteresisEnabled) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.swap_vert,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Switch(value: config.isEnabled, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}
