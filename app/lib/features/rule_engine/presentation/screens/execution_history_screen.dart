import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/rule_execution.dart';
import '../providers/rule_provider.dart';

class ExecutionHistoryScreen extends ConsumerWidget {
  final String ruleId;

  const ExecutionHistoryScreen({super.key, required this.ruleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionsAsync = ref.watch(ruleExecutionsProvider(ruleId));

    return Scaffold(
      appBar: AppBar(title: const Text('Execution History')),
      body: executionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalSm,
              Text(
                'Failed to load executions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppSpacing.verticalSm,
              FilledButton(
                onPressed: () => ref.invalidate(ruleExecutionsProvider(ruleId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (executions) {
          if (executions.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history,
              title: 'No executions yet',
              subtitle: 'This rule has not been triggered. Enable it or run a dry run.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(ruleExecutionsProvider(ruleId)),
            child: ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: executions.length,
              separatorBuilder: (_, __) => AppSpacing.verticalSm,
              itemBuilder: (context, index) =>
                  _ExecutionCard(execution: executions[index]),
            ),
          );
        },
      ),
    );
  }
}

class _ExecutionCard extends StatelessWidget {
  final RuleExecution execution;

  const _ExecutionCard({required this.execution});

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

    // Build a short trigger summary from triggerData
    String triggerSummary;
    if (execution.triggerData.containsKey('event_type')) {
      triggerSummary = execution.triggerData['event_type'].toString();
    } else if (execution.triggerData.isNotEmpty) {
      triggerSummary = execution.triggerData.keys.take(2).join(', ');
    } else {
      triggerSummary = 'Manual trigger';
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.ruleExecutionDetail,
          pathParameters: {'id': execution.id},
        ),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              AppSpacing.horizontalSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          execution.status.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: color,
                          ),
                        ),
                        if (execution.dryRun) ...[
                          AppSpacing.horizontalSm,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DRY RUN',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      triggerSummary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      execution.startedAt.formattedWithTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                duration,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.horizontalSm,
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
