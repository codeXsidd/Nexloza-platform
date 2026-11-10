import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../theme/app_spacing.dart';
import '../../data/rule_repository.dart';
import '../../domain/entities/rule_execution.dart';
import '../../domain/entities/rule_graph.dart';
import '../providers/rule_provider.dart';

class RuleDetailScreen extends ConsumerWidget {
  final String ruleId;

  const RuleDetailScreen({super.key, required this.ruleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruleAsync = ref.watch(ruleDetailProvider(ruleId));

    return Scaffold(
      appBar: ruleAsync.whenOrNull(
        data: (rule) => rule != null
            ? AppBar(
                title: Text(rule.name),
                actions: [
                  PopupMenuButton<_MenuAction>(
                    onSelected: (action) =>
                        _handleMenuAction(context, ref, action, rule),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: _MenuAction.edit,
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (rule.status.canPublish)
                        const PopupMenuItem(
                          value: _MenuAction.publish,
                          child: ListTile(
                            leading: Icon(Icons.publish),
                            title: Text('Publish'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      if (rule.status.canEnable)
                        const PopupMenuItem(
                          value: _MenuAction.enable,
                          child: ListTile(
                            leading: Icon(Icons.play_arrow),
                            title: Text('Enable'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      if (rule.status.isActive)
                        const PopupMenuItem(
                          value: _MenuAction.disable,
                          child: ListTile(
                            leading: Icon(Icons.pause),
                            title: Text('Disable'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuItem(
                        value: _MenuAction.archive,
                        child: ListTile(
                          leading: Icon(Icons.archive),
                          title: Text('Archive'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: _MenuAction.delete,
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title:
                              Text('Delete', style: TextStyle(color: Colors.red)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : AppBar(title: const Text('Rule Detail')),
      ) ??
          AppBar(title: const Text('Rule Detail')),
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
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppSpacing.verticalSm,
              FilledButton(
                onPressed: () => ref.invalidate(ruleDetailProvider(ruleId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (rule) {
          if (rule == null) {
            return const Center(child: Text('Rule not found'));
          }
          return _RuleDetailBody(ruleId: ruleId, rule: rule);
        },
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    _MenuAction action,
    RuleAutomation rule,
  ) async {
    final controller = ref.read(ruleControllerProvider);

    switch (action) {
      case _MenuAction.edit:
        context.pushNamed(
          RouteNames.ruleEditor,
          pathParameters: {'id': ruleId},
        );
      case _MenuAction.publish:
        final ok = await controller.publishRule(ruleId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok ? 'Rule published' : 'Failed to publish rule'),
            ),
          );
        }
        ref.invalidate(ruleDetailProvider(ruleId));
      case _MenuAction.enable:
        await controller.enableRule(ruleId);
        ref.invalidate(ruleDetailProvider(ruleId));
      case _MenuAction.disable:
        await controller.disableRule(ruleId);
        ref.invalidate(ruleDetailProvider(ruleId));
      case _MenuAction.archive:
        final confirmed = await showConfirmationDialog(
          context,
          title: 'Archive Rule',
          message:
              'Are you sure you want to archive "${rule.name}"? It will be disabled.',
          confirmLabel: 'Archive',
          isDestructive: true,
        );
        if (confirmed) {
          await controller.archiveRule(ruleId);
          ref.invalidate(ruleDetailProvider(ruleId));
        }
      case _MenuAction.delete:
        final confirmed = await showConfirmationDialog(
          context,
          title: 'Delete Rule',
          message:
              'Are you sure you want to permanently delete "${rule.name}"? This cannot be undone.',
          confirmLabel: 'Delete',
          isDestructive: true,
        );
        if (confirmed) {
          await controller.deleteRule(ruleId);
          if (context.mounted) context.pop();
        }
    }
  }
}

enum _MenuAction { edit, publish, enable, disable, archive, delete }

class _RuleDetailBody extends ConsumerWidget {
  final String ruleId;
  final RuleAutomation rule;

  const _RuleDetailBody({required this.ruleId, required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final versionsAsync = ref.watch(ruleVersionsProvider(ruleId));
    final executionsAsync = ref.watch(ruleExecutionsProvider(ruleId));

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        // Status banner
        _StatusBanner(status: rule.status),

        AppSpacing.verticalMd,

        // Info card
        Card(
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configuration', style: theme.textTheme.titleSmall),
                AppSpacing.verticalSm,
                if (rule.description != null &&
                    rule.description!.isNotEmpty) ...[
                  Text(
                    rule.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.verticalSm,
                ],
                _InfoRow(label: 'Priority', value: '${rule.priority}'),
                _InfoRow(
                  label: 'Cooldown',
                  value: '${rule.cooldownSeconds}s',
                ),
                _InfoRow(
                  label: 'Max Executions/hr',
                  value: '${rule.maxExecutionsPerHour}',
                ),
                _InfoRow(
                  label: 'Created',
                  value: rule.createdAt.formattedWithTime,
                ),
              ],
            ),
          ),
        ),

        AppSpacing.verticalMd,

        // Graph preview
        Card(
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_tree,
                        color: theme.colorScheme.primary, size: 20),
                    AppSpacing.horizontalSm,
                    Text('Rule Graph', style: theme.textTheme.titleSmall),
                  ],
                ),
                AppSpacing.verticalSm,
                if (rule.ruleGraph != null) ...[
                  Text(
                    '${rule.ruleGraph!.nodes.length} nodes, '
                    '${rule.ruleGraph!.edges.length} edges '
                    '(v${rule.graphVersion})',
                    style: theme.textTheme.bodyMedium,
                  ),
                  AppSpacing.verticalSm,
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.pushNamed(
                        RouteNames.ruleEditor,
                        pathParameters: {'id': ruleId},
                      ),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open Editor'),
                    ),
                  ),
                ] else
                  Text(
                    'No graph defined yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),

        AppSpacing.verticalMd,

        // Version history
        versionsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (versions) {
            if (versions.isEmpty) return const SizedBox.shrink();
            final latest = versions.first;
            return Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history,
                            color: theme.colorScheme.primary, size: 20),
                        AppSpacing.horizontalSm,
                        Text('Version History',
                            style: theme.textTheme.titleSmall),
                      ],
                    ),
                    AppSpacing.verticalSm,
                    Text(
                      'Latest: v${latest.versionNumber}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'Published ${latest.publishedAt.formattedWithTime}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (versions.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${versions.length} versions total',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        AppSpacing.verticalMd,

        // Recent executions
        executionsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (executions) {
            return Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.list_alt,
                            color: theme.colorScheme.primary, size: 20),
                        AppSpacing.horizontalSm,
                        Text('Recent Executions',
                            style: theme.textTheme.titleSmall),
                      ],
                    ),
                    AppSpacing.verticalSm,
                    if (executions.isEmpty)
                      Text(
                        'No executions yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else ...[
                      for (final exec in executions.take(5))
                        _ExecutionTile(execution: exec),
                      AppSpacing.verticalSm,
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.pushNamed(
                            RouteNames.ruleExecutionHistory,
                            pathParameters: {'id': ruleId},
                          ),
                          child: const Text('View All Executions'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),

        AppSpacing.verticalMd,

        // Dry Run button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.pushNamed(
              RouteNames.ruleDryRun,
              pathParameters: {'id': ruleId},
            ),
            icon: const Icon(Icons.science),
            label: const Text('Dry Run'),
          ),
        ),

        AppSpacing.verticalLg,
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final RuleStatus status;

  const _StatusBanner({required this.status});

  Color _statusColor() {
    return switch (status) {
      RuleStatus.draft => Colors.grey,
      RuleStatus.validated => Colors.blue,
      RuleStatus.published => Colors.amber,
      RuleStatus.enabled => Colors.green,
      RuleStatus.disabled => Colors.red,
      RuleStatus.archived => Colors.brown,
    };
  }

  IconData _statusIcon() {
    return switch (status) {
      RuleStatus.draft => Icons.edit_note,
      RuleStatus.validated => Icons.check_circle_outline,
      RuleStatus.published => Icons.publish,
      RuleStatus.enabled => Icons.play_circle_filled,
      RuleStatus.disabled => Icons.pause_circle_filled,
      RuleStatus.archived => Icons.archive,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final theme = Theme.of(context);

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Icon(_statusIcon(), color: color),
            AppSpacing.horizontalSm,
            Text(
              status.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ExecutionTile extends StatelessWidget {
  final RuleExecution execution;

  const _ExecutionTile({required this.execution});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, color) = switch (execution.status) {
      ExecutionStatus.completed => (Icons.check_circle, Colors.green),
      ExecutionStatus.failed => (Icons.error, Colors.red),
      ExecutionStatus.running => (Icons.hourglass_top, Colors.amber),
      ExecutionStatus.cancelled => (Icons.cancel, Colors.grey),
    };

    final duration = execution.durationMs != null
        ? '${execution.durationMs}ms'
        : '--';

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        execution.startedAt.formattedWithTime,
        style: theme.textTheme.bodyMedium,
      ),
      trailing: Text(duration, style: theme.textTheme.bodySmall),
    );
  }
}
