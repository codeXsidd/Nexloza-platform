import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../domain/entities/dashboard_widget_entity.dart';

class ValueDisplayWidgetCard extends StatelessWidget {
  final DashboardWidget widget;

  const ValueDisplayWidgetCard({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = widget.config['value']?.toString() ?? '--';
    final unit = widget.config['unit'] as String? ?? '';
    final label = widget.config['label'] as String? ?? '';

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
                  Text(
                    '$value$unit',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (label.isNotEmpty)
                    Text(
                      label,
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
