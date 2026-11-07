import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';

class ProjectSummaryCard extends StatelessWidget {
  const ProjectSummaryCard({super.key});

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
                Icon(Icons.folder, color: theme.colorScheme.primary),
                AppSpacing.horizontalSm,
                Text('Projects', style: theme.textTheme.titleMedium),
              ],
            ),
            AppSpacing.verticalMd,
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Total',
                    value: '0',
                    icon: Icons.folder_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                AppSpacing.horizontalSm,
                Expanded(
                  child: _StatTile(
                    label: 'Active',
                    value: '0',
                    icon: Icons.play_circle_outline,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(color: color),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
