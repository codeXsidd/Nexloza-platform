import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum AlarmSeverityLevel { critical, high, medium, warning, info }

class NexAlarmCard extends StatelessWidget {
  final String title;
  final String? description;
  final String? deviceName;
  final AlarmSeverityLevel severity;
  final String? timestamp;
  final bool isAcknowledged;
  final VoidCallback? onTap;
  final VoidCallback? onAcknowledge;

  const NexAlarmCard({
    super.key,
    required this.title,
    this.description,
    this.deviceName,
    required this.severity,
    this.timestamp,
    this.isAcknowledged = false,
    this.onTap,
    this.onAcknowledge,
  });

  Color get _severityColor => switch (severity) {
    AlarmSeverityLevel.critical => AppColors.alarmCritical,
    AlarmSeverityLevel.high => AppColors.alarmHigh,
    AlarmSeverityLevel.medium => AppColors.alarmMedium,
    AlarmSeverityLevel.warning => AppColors.alarmWarning,
    AlarmSeverityLevel.info => AppColors.alarmInfo,
  };

  IconData get _severityIcon => switch (severity) {
    AlarmSeverityLevel.critical => Icons.error,
    AlarmSeverityLevel.high => Icons.warning_amber,
    AlarmSeverityLevel.medium => Icons.notification_important,
    AlarmSeverityLevel.warning => Icons.info_outline,
    AlarmSeverityLevel.info => Icons.info_outline,
  };

  String get _severityLabel => switch (severity) {
    AlarmSeverityLevel.critical => 'Critical',
    AlarmSeverityLevel.high => 'High',
    AlarmSeverityLevel.medium => 'Medium',
    AlarmSeverityLevel.warning => 'Warning',
    AlarmSeverityLevel.info => 'Info',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: _severityColor, width: 4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _severityColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_severityIcon, color: _severityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _severityColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _severityLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: _severityColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (isAcknowledged) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.success,
                          ),
                        ],
                        const Spacer(),
                        if (timestamp != null)
                          Text(
                            timestamp!,
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(title, style: textTheme.titleSmall),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (deviceName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.devices_other,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            deviceName!,
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onAcknowledge != null && !isAcknowledged)
                IconButton(
                  icon: const Icon(Icons.check, size: 20),
                  onPressed: onAcknowledge,
                  tooltip: 'Acknowledge',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
