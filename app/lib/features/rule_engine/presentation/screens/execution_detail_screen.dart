import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/rule_execution.dart';
import '../providers/rule_provider.dart';

class ExecutionDetailScreen extends ConsumerWidget {
  final String executionId;

  const ExecutionDetailScreen({super.key, required this.executionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execAsync = ref.watch(executionDetailProvider(executionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Execution Detail')),
      body: execAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalSm,
              Text(
                'Failed to load execution',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppSpacing.verticalSm,
              FilledButton(
                onPressed: () =>
                    ref.invalidate(executionDetailProvider(executionId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (execution) {
          if (execution == null) {
            return const Center(child: Text('Execution not found'));
          }
          return _ExecutionDetailBody(execution: execution);
        },
      ),
    );
  }
}

class _ExecutionDetailBody extends StatelessWidget {
  final RuleExecution execution;

  const _ExecutionDetailBody({required this.execution});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (statusIcon, statusColor) = switch (execution.status) {
      ExecutionStatus.completed => (Icons.check_circle, Colors.green),
      ExecutionStatus.failed => (Icons.error, Colors.red),
      ExecutionStatus.running => (Icons.hourglass_top, Colors.amber),
      ExecutionStatus.cancelled => (Icons.cancel, Colors.grey),
    };

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        // Header card
        Card(
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 28),
                    AppSpacing.horizontalSm,
                    Text(
                      execution.status.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (execution.dryRun)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
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
                ),
                AppSpacing.verticalMd,
                _DetailRow(
                  label: 'Started',
                  value: execution.startedAt.formattedWithTime,
                ),
                if (execution.completedAt != null)
                  _DetailRow(
                    label: 'Completed',
                    value: execution.completedAt!.formattedWithTime,
                  ),
                if (execution.durationMs != null)
                  _DetailRow(
                    label: 'Duration',
                    value: '${execution.durationMs}ms',
                  ),
                if (execution.correlationId != null)
                  _DetailRow(
                    label: 'Correlation ID',
                    value: execution.correlationId!,
                  ),
                _DetailRow(
                  label: 'Depth',
                  value: '${execution.executionDepth}',
                ),
                if (execution.errorMessage != null) ...[
                  AppSpacing.verticalSm,
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.verticalXs,
                        Text(
                          execution.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        AppSpacing.verticalMd,

        // Trigger data card
        Card(
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bolt,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    AppSpacing.horizontalSm,
                    Text('Trigger Data', style: theme.textTheme.titleSmall),
                  ],
                ),
                AppSpacing.verticalSm,
                if (execution.triggerData.isEmpty)
                  Text(
                    'No trigger data',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...execution.triggerData.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              e.key,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${e.value}',
                              style: theme.textTheme.bodySmall,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        AppSpacing.verticalMd,

        // Node results timeline
        Card(
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timeline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    AppSpacing.horizontalSm,
                    Text('Node Results', style: theme.textTheme.titleSmall),
                  ],
                ),
                AppSpacing.verticalSm,
                if (execution.nodeResults.isEmpty)
                  Text(
                    'No node results recorded',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  for (int i = 0; i < execution.nodeResults.length; i++)
                    _NodeResultTile(
                      result: execution.nodeResults[i],
                      isLast: i == execution.nodeResults.length - 1,
                    ),
              ],
            ),
          ),
        ),

        AppSpacing.verticalLg,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _NodeResultTile extends StatelessWidget {
  final NodeResult result;
  final bool isLast;

  const _NodeResultTile({required this.result, required this.isLast});

  Color _statusColor() {
    return switch (result.status) {
      'evaluated' || 'completed' || 'success' => Colors.green,
      'skipped' => Colors.grey,
      'failed' || 'error' => Colors.red,
      _ => Colors.grey,
    };
  }

  IconData _nodeTypeIcon() {
    return switch (result.nodeType) {
      'telemetry_received' ||
      'device_online_trigger' ||
      'device_offline_trigger' ||
      'device_status_changed' ||
      'sensor_value_changed' ||
      'sensor_above_threshold' ||
      'sensor_below_threshold' ||
      'twin_reported_changed' ||
      'twin_desired_changed' ||
      'scheduled_trigger' ||
      'manual_trigger' => Icons.bolt,
      'equal_to' ||
      'not_equal_to' ||
      'greater_than' ||
      'greater_than_or_equal' ||
      'less_than' ||
      'less_than_or_equal' ||
      'between_range' ||
      'boolean_check' ||
      'and_gate' ||
      'or_gate' ||
      'not_gate' ||
      'device_online_check' ||
      'twin_desired_vs_reported' => Icons.rule,
      'send_command' ||
      'set_actuator' ||
      'update_twin_desired' ||
      'execute_scene' ||
      'record_event' ||
      'log_result' => Icons.play_circle,
      'delay' ||
      'conditional_branch' ||
      'merge' ||
      'stop_flow' ||
      'terminate' => Icons.call_split,
      _ => Icons.circle_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor();

    final outputText = result.output != null ? '${result.output}' : null;
    final truncatedOutput = outputText != null && outputText.length > 100
        ? '${outputText.substring(0, 100)}...'
        : outputText;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_nodeTypeIcon(), size: 16, color: color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          result.nodeType.replaceAll('_', ' '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          result.status,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Node: ${result.nodeId}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    result.evaluatedAt.formattedWithTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (truncatedOutput != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        truncatedOutput,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (result.error != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        result.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
