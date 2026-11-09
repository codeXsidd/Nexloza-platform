import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_spacing.dart';
import '../../../projects/presentation/providers/project_provider.dart';

class ProjectSummaryCard extends ConsumerWidget {
  const ProjectSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsProvider);

    return projectsAsync.when(
      loading: () => Card(
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
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Card(
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
                      value: '--',
                      icon: Icons.folder_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  AppSpacing.horizontalSm,
                  Expanded(
                    child: _StatTile(
                      label: 'Active',
                      value: '--',
                      icon: Icons.play_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      data: (projects) {
        final total = projects.length;
        final active = projects.where((p) => p.isActive).length;

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
                        value: '$total',
                        icon: Icons.folder_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    AppSpacing.horizontalSm,
                    Expanded(
                      child: _StatTile(
                        label: 'Active',
                        value: '$active',
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
      },
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
