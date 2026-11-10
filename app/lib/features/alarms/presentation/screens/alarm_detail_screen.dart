import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_spacing.dart';
import '../../domain/entities/alarm_entity.dart';
import '../../domain/entities/alarm_activity_entity.dart';
import '../../domain/entities/alarm_status.dart';
import '../providers/alarm_providers.dart';

class AlarmDetailScreen extends ConsumerStatefulWidget {
  final String alarmId;

  const AlarmDetailScreen({super.key, required this.alarmId});

  @override
  ConsumerState<AlarmDetailScreen> createState() => _AlarmDetailScreenState();
}

class _AlarmDetailScreenState extends ConsumerState<AlarmDetailScreen> {
  Future<void> _acknowledge() async {
    final notifier = ref.read(alarmActionProvider);
    final success = await notifier.acknowledgeAlarm(widget.alarmId);
    if (success && mounted) {
      ref.invalidate(alarmDetailProvider(widget.alarmId));
      ref.invalidate(alarmActivityProvider(widget.alarmId));
    }
  }

  Future<void> _clear() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Alarm'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Why is this alarm being cleared?',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
                ctx, controller.text.trim().isEmpty ? 'Manually cleared' : controller.text.trim()),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;

    final notifier = ref.read(alarmActionProvider);
    final success = await notifier.clearAlarm(widget.alarmId, reason: reason);
    if (success && mounted) {
      ref.invalidate(alarmDetailProvider(widget.alarmId));
      ref.invalidate(alarmActivityProvider(widget.alarmId));
    }
  }

  Future<void> _addComment() async {
    final controller = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Comment',
            hintText: 'Enter your comment...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (comment == null || !mounted) return;

    final notifier = ref.read(alarmActionProvider);
    final success = await notifier.addComment(widget.alarmId, comment);
    if (success && mounted) {
      ref.invalidate(alarmActivityProvider(widget.alarmId));
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final alarmAsync = ref.watch(alarmDetailProvider(widget.alarmId));
    final activityAsync = ref.watch(alarmActivityProvider(widget.alarmId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Alarm Detail')),
      body: alarmAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalSm,
              Text('Failed to load alarm', style: theme.textTheme.titleMedium),
              AppSpacing.verticalSm,
              FilledButton(
                onPressed: () =>
                    ref.invalidate(alarmDetailProvider(widget.alarmId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (alarm) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(alarmDetailProvider(widget.alarmId));
            ref.invalidate(alarmActivityProvider(widget.alarmId));
          },
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // Header
              _HeaderSection(alarm: alarm),
              AppSpacing.verticalLg,

              // Info cards
              _InfoSection(
                alarm: alarm,
                formatDateTime: _formatDateTime,
                formatDuration: _formatDuration,
              ),
              AppSpacing.verticalLg,

              // Actions
              if (alarm.status != AlarmStatus.cleared)
                _ActionsSection(
                  alarm: alarm,
                  onAcknowledge: alarm.isActive ? _acknowledge : null,
                  onClear: _clear,
                  onAddComment: _addComment,
                ),

              if (alarm.status == AlarmStatus.cleared)
                _ActionsSection(
                  alarm: alarm,
                  onAcknowledge: null,
                  onClear: null,
                  onAddComment: _addComment,
                ),

              AppSpacing.verticalLg,

              // Activity timeline
              Text('Activity Timeline', style: theme.textTheme.titleMedium),
              AppSpacing.verticalSm,
              activityAsync.when(
                loading: () => const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )),
                error: (e, _) => Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Text('Failed to load activity: $e'),
                  ),
                ),
                data: (activities) {
                  if (activities.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: AppSpacing.cardPadding,
                        child: Text(
                          'No activity recorded.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: activities
                        .map((a) => _ActivityTile(
                            activity: a, formatDateTime: _formatDateTime))
                        .toList(),
                  );
                },
              ),
              AppSpacing.verticalLg,
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final Alarm alarm;

  const _HeaderSection({required this.alarm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(alarm.severity.icon, color: alarm.severity.color, size: 32),
                AppSpacing.horizontalSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alarm.title, style: theme.textTheme.titleLarge),
                      if (alarm.message != null && alarm.message!.isNotEmpty)
                        Text(
                          alarm.message!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMd,
            Row(
              children: [
                _Badge(
                  label: alarm.severity.displayName,
                  color: alarm.severity.color,
                ),
                const SizedBox(width: 8),
                _Badge(
                  label: alarm.status.displayName,
                  color: alarm.status.color,
                ),
                const SizedBox(width: 8),
                _Badge(
                  label: alarm.source.displayName,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Alarm alarm;
  final String Function(DateTime) formatDateTime;
  final String Function(Duration) formatDuration;

  const _InfoSection({
    required this.alarm,
    required this.formatDateTime,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: theme.textTheme.titleSmall),
            AppSpacing.verticalSm,
            _InfoRow(label: 'Category', value: alarm.category),
            _InfoRow(label: 'Source', value: alarm.source.displayName),
            if (alarm.deviceId != null)
              _InfoRow(label: 'Device ID', value: alarm.deviceId!),
            if (alarm.conditionValue != null)
              _InfoRow(
                  label: 'Condition Value',
                  value: alarm.conditionValue!.toStringAsFixed(2)),
            if (alarm.thresholdValue != null)
              _InfoRow(
                  label: 'Threshold',
                  value: alarm.thresholdValue!.toStringAsFixed(2)),
            _InfoRow(
                label: 'Occurrences',
                value: alarm.occurrenceCount.toString()),
            _InfoRow(
                label: 'First Occurred',
                value: formatDateTime(alarm.firstOccurredAt)),
            _InfoRow(
                label: 'Last Occurred',
                value: formatDateTime(alarm.lastOccurredAt)),
            _InfoRow(label: 'Duration', value: formatDuration(alarm.duration)),
            if (alarm.acknowledgedAt != null)
              _InfoRow(
                  label: 'Acknowledged At',
                  value: formatDateTime(alarm.acknowledgedAt!)),
            if (alarm.clearedAt != null)
              _InfoRow(
                  label: 'Cleared At',
                  value: formatDateTime(alarm.clearedAt!)),
            if (alarm.clearedReason != null)
              _InfoRow(label: 'Clear Reason', value: alarm.clearedReason!),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onClear;
  final VoidCallback? onAddComment;

  const _ActionsSection({
    required this.alarm,
    this.onAcknowledge,
    this.onClear,
    this.onAddComment,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (onAcknowledge != null)
          FilledButton.tonal(
            onPressed: onAcknowledge,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 18),
                SizedBox(width: 6),
                Text('Acknowledge'),
              ],
            ),
          ),
        if (onClear != null)
          FilledButton(
            onPressed: onClear,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 18),
                SizedBox(width: 6),
                Text('Clear Alarm'),
              ],
            ),
          ),
        if (onAddComment != null)
          OutlinedButton(
            onPressed: onAddComment,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.comment, size: 18),
                SizedBox(width: 6),
                Text('Add Comment'),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final AlarmActivity activity;
  final String Function(DateTime) formatDateTime;

  const _ActivityTile({required this.activity, required this.formatDateTime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: Icon(
          activity.activityType.icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          activity.activityType.displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity.comment != null)
              Text(activity.comment!, style: theme.textTheme.bodySmall),
            if (activity.previousSeverity != null &&
                activity.newSeverity != null)
              Text(
                '${activity.previousSeverity!.displayName} → ${activity.newSeverity!.displayName}',
                style: theme.textTheme.bodySmall,
              ),
            Text(
              formatDateTime(activity.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
