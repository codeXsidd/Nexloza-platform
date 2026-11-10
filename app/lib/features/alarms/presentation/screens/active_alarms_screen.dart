import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/alarm_entity.dart';
import '../providers/alarm_providers.dart';

class ActiveAlarmsScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ActiveAlarmsScreen({super.key, required this.projectId});

  @override
  ConsumerState<ActiveAlarmsScreen> createState() => _ActiveAlarmsScreenState();
}

class _ActiveAlarmsScreenState extends ConsumerState<ActiveAlarmsScreen> {
  final Set<String> _selected = {};
  bool _selectionMode = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      _selectionMode = _selected.isNotEmpty;
    });
  }

  Future<void> _bulkAcknowledge() async {
    if (_selected.isEmpty) return;
    final notifier = ref.read(alarmActionProvider);
    final success = await notifier.bulkAcknowledge(
      widget.projectId,
      _selected.toList(),
    );
    if (success && mounted) {
      setState(() {
        _selected.clear();
        _selectionMode = false;
      });
      ref.invalidate(activeAlarmsProvider(widget.projectId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final alarmsAsync = ref.watch(activeAlarmsProvider(widget.projectId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectionMode ? '${_selected.length} selected' : 'Active Alarms',
        ),
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Acknowledge Selected',
              onPressed: _bulkAcknowledge,
            ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel Selection',
              onPressed: () => setState(() {
                _selected.clear();
                _selectionMode = false;
              }),
            ),
        ],
      ),
      body: alarmsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalSm,
              Text('Failed to load alarms', style: theme.textTheme.titleMedium),
              AppSpacing.verticalSm,
              FilledButton(
                onPressed: () =>
                    ref.invalidate(activeAlarmsProvider(widget.projectId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (alarms) {
          if (alarms.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.check_circle_outline,
              title: 'No Active Alarms',
              subtitle: 'All systems are operating normally.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(activeAlarmsProvider(widget.projectId)),
            child: ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: alarms.length,
              separatorBuilder: (_, __) => AppSpacing.verticalSm,
              itemBuilder: (context, index) {
                final alarm = alarms[index];
                final isSelected = _selected.contains(alarm.id);
                return _AlarmCard(
                  alarm: alarm,
                  isSelected: isSelected,
                  selectionMode: _selectionMode,
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelection(alarm.id);
                    } else {
                      context.pushNamed(
                        RouteNames.alarmDetail,
                        pathParameters: {'id': alarm.id},
                      );
                    }
                  },
                  onLongPress: () => _toggleSelection(alarm.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AlarmCard({
    required this.alarm,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: theme.colorScheme.primary,
                  ),
                ),
              Icon(alarm.severity.icon, color: alarm.severity.color, size: 28),
              AppSpacing.horizontalSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: alarm.severity.color.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            alarm.severity.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: alarm.severity.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                        if (alarm.occurrenceCount > 1) ...[
                          const SizedBox(width: 6),
                          Text(
                            'x${alarm.occurrenceCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _timeAgo(alarm.lastOccurredAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
