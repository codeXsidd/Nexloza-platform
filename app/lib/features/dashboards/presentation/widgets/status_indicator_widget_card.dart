import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/dashboard_widget_entity.dart';

class StatusIndicatorWidgetCard extends StatelessWidget {
  final DashboardWidget widget;

  const StatusIndicatorWidgetCard({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = widget.config['is_online'] as bool? ?? false;
    final statusText =
        widget.config['status'] as String? ?? (isOnline ? 'Online' : 'Offline');
    final details = widget.config['details'] as String? ?? '';

    final color = isOnline ? AppColors.online : AppColors.offline;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: theme.textTheme.titleSmall),
            const Spacer(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withAlpha(30),
                    ),
                    child: Icon(
                      isOnline ? Icons.check_circle : Icons.cancel,
                      color: color,
                      size: 28,
                    ),
                  ),
                  AppSpacing.verticalSm,
                  Text(
                    statusText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
