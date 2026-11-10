import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/alarm_entity.dart';
import '../../domain/entities/alarm_status.dart';
import '../providers/alarm_providers.dart';

class AlarmHistoryScreen extends ConsumerStatefulWidget {
  final String projectId;

  const AlarmHistoryScreen({super.key, required this.projectId});

  @override
  ConsumerState<AlarmHistoryScreen> createState() => _AlarmHistoryScreenState();
}

class _AlarmHistoryScreenState extends ConsumerState<AlarmHistoryScreen> {
  AlarmStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(alarmHistoryProvider(widget.projectId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Alarm History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _statusFilter == null,
                    onSelected: (_) => setState(() => _statusFilter = null),
                  ),
                  const SizedBox(width: 8),
                  for (final status in AlarmStatus.values) ...[
                    FilterChip(
                      label: Text(status.displayName),
                      selected: _statusFilter == status,
                      selectedColor: status.color.withAlpha(40),
                      onSelected: (_) =>
                          setState(() => _statusFilter = status),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    AppSpacing.verticalSm,
                    Text('Failed to load alarm history',
                        style: theme.textTheme.titleMedium),
                    AppSpacing.verticalSm,
                    FilledButton(
                      onPressed: () => ref.invalidate(
                          alarmHistoryProvider(widget.projectId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (alarms) {
                final filtered = _statusFilter == null
                    ? alarms
                    : alarms
                        .where((a) => a.status == _statusFilter)
                        .toList();
                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.history,
                    title: 'No Alarms Found',
                    subtitle: _statusFilter != null
                        ? 'No ${_statusFilter!.displayName.toLowerCase()} alarms.'
                        : 'No alarm history yet.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref
                      .invalidate(alarmHistoryProvider(widget.projectId)),
                  child: ListView.separated(
                    padding: AppSpacing.screenPadding,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => AppSpacing.verticalSm,
                    itemBuilder: (context, index) {
                      final alarm = filtered[index];
                      return _HistoryTile(alarm: alarm);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Alarm alarm;

  const _HistoryTile({required this.alarm});

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(alarm.severity.icon, color: alarm.severity.color),
        title: Text(
          alarm.title,
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: alarm.status.color.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                alarm.status.displayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: alarm.status.color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatDate(alarm.lastOccurredAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () => context.pushNamed(
          RouteNames.alarmDetail,
          pathParameters: {'id': alarm.id},
        ),
      ),
    );
  }
}
