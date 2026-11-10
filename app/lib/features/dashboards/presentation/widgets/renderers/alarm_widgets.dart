import 'package:flutter/material.dart';

import '../../../domain/entities/dashboard_widget_entity.dart';
import '../../../domain/widget_registry.dart';

Widget buildAlarmCount(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  if (data.isLoading) {
    return Card(
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
  final count = data.numericValue.toInt();
  final hasAlarms = count > 0;
  return Card(
    color: hasAlarms ? theme.colorScheme.errorContainer : null,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_active,
            size: 32,
            color: hasAlarms ? theme.colorScheme.error : Colors.green,
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: hasAlarms ? theme.colorScheme.error : Colors.green,
            ),
          ),
          Text(
            widget.title,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

Widget buildCriticalAlarmCount(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  if (data.isLoading) {
    return Card(
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
  final count = data.numericValue.toInt();
  final hasCritical = count > 0;
  return Card(
    color: hasCritical ? Colors.red.shade50 : null,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error,
            size: 32,
            color: hasCritical ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: hasCritical ? Colors.red : Colors.green,
            ),
          ),
          Text(
            widget.title,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

Widget buildUnacknowledgedAlarmCount(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  if (data.isLoading) {
    return Card(
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
  final count = data.numericValue.toInt();
  final hasUnack = count > 0;
  return Card(
    color: hasUnack ? Colors.orange.shade50 : null,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning,
            size: 32,
            color: hasUnack ? Colors.orange : Colors.green,
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: hasUnack ? Colors.orange : Colors.green,
            ),
          ),
          Text(
            widget.title,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

Widget buildAlarmSeverityDistribution(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  if (data.isLoading) {
    return Card(
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  final distribution = <String, int>{};
  if (data.currentValue is Map) {
    for (final entry in (data.currentValue as Map).entries) {
      distribution[entry.key.toString()] = (entry.value as num?)?.toInt() ?? 0;
    }
  }

  final severityColors = {
    'critical': Colors.red,
    'high': Colors.deepOrange,
    'medium': Colors.orange,
    'warning': Colors.amber,
    'informational': Colors.blue,
  };

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (distribution.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No alarms',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: distribution.entries.map((entry) {
                  final color =
                      severityColors[entry.key] ?? theme.colorScheme.outline;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key[0].toUpperCase() + entry.key.substring(1),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget buildRecentAlarmActivity(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  if (data.isLoading) {
    return Card(
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  final alarms = <Map<String, dynamic>>[];
  if (data.currentValue is List) {
    for (final item in data.currentValue as List) {
      if (item is Map<String, dynamic>) {
        alarms.add(item);
      }
    }
  }

  final severityColors = {
    'critical': Colors.red,
    'high': Colors.deepOrange,
    'medium': Colors.orange,
    'warning': Colors.amber,
    'informational': Colors.blue,
  };

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${alarms.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (alarms.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No recent activity',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: alarms.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final alarm = alarms[i];
                  final severity = (alarm['severity'] as String? ?? 'warning')
                      .toLowerCase();
                  final color =
                      severityColors[severity] ?? theme.colorScheme.outline;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alarm['title'] as String? ?? 'Alarm',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (alarm['status'] != null)
                                Text(
                                  alarm['status'] as String,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );
}
