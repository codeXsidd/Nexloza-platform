import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/alarm_entity.dart';
import '../../domain/entities/alarm_severity.dart';
import '../providers/alarm_providers.dart';

class AlarmsOverviewScreen extends ConsumerWidget {
  final String projectId;

  const AlarmsOverviewScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(alarmStatsProvider(projectId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Alarms')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(alarmStatsProvider(projectId)),
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            Text('Alarm Summary', style: theme.textTheme.titleMedium),
            AppSpacing.verticalMd,
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Text(
                    'Failed to load stats: $e',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
              data: (stats) => _StatsGrid(stats: stats),
            ),
            AppSpacing.verticalLg,
            Text('Quick Actions', style: theme.textTheme.titleMedium),
            AppSpacing.verticalMd,
            _QuickActionTile(
              icon: Icons.warning_amber,
              label: 'Active Alarms',
              subtitle: 'View and manage active alarms',
              color: Colors.red,
              onTap: () => context.pushNamed(
                RouteNames.activeAlarms,
                queryParameters: {'projectId': projectId},
              ),
            ),
            AppSpacing.verticalSm,
            _QuickActionTile(
              icon: Icons.history,
              label: 'Alarm History',
              subtitle: 'Browse past alarms',
              color: Colors.blueGrey,
              onTap: () => context.pushNamed(
                RouteNames.alarmHistory,
                queryParameters: {'projectId': projectId},
              ),
            ),
            AppSpacing.verticalSm,
            _QuickActionTile(
              icon: Icons.settings,
              label: 'Configurations',
              subtitle: 'Manage alarm thresholds and rules',
              color: Colors.teal,
              onTap: () => context.pushNamed(
                RouteNames.alarmConfigurations,
                queryParameters: {'projectId': projectId},
              ),
            ),
            AppSpacing.verticalSm,
            _QuickActionTile(
              icon: Icons.trending_up,
              label: 'Escalation Policies',
              subtitle: 'Configure escalation stages',
              color: Colors.deepPurple,
              onTap: () => context.pushNamed(
                RouteNames.escalationPolicies,
                queryParameters: {'projectId': projectId},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AlarmStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
          label: 'Critical',
          count: stats.criticalCount,
          color: AlarmSeverity.critical.color,
        ),
        _StatCard(
          label: 'High',
          count: stats.highCount,
          color: AlarmSeverity.high.color,
        ),
        _StatCard(
          label: 'Medium',
          count: stats.mediumCount,
          color: AlarmSeverity.medium.color,
        ),
        _StatCard(
          label: 'Warning',
          count: stats.warningCount,
          color: AlarmSeverity.warning.color,
        ),
        _StatCard(
          label: 'Unacknowledged',
          count: stats.unacknowledgedCount,
          color: Colors.red,
        ),
        _StatCard(
          label: 'Total Active',
          count: stats.totalActive,
          color: Colors.blueGrey,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48 - 12) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: count > 0 ? color : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: theme.textTheme.titleSmall),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
