import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/app_spacing.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: theme.textTheme.titleMedium),
            AppSpacing.verticalMd,
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionChip(
                  icon: Icons.add_circle_outline,
                  label: 'New Project',
                  onTap: () => context.pushNamed(RouteNames.createProject),
                ),
                _ActionChip(
                  icon: Icons.add_to_queue,
                  label: 'Add Device',
                  onTap: () => context.pushNamed(RouteNames.addDevice),
                ),
                _ActionChip(
                  icon: Icons.auto_awesome,
                  label: 'Automation',
                  onTap: () => context.pushNamed(RouteNames.createAutomation),
                ),
                _ActionChip(
                  icon: Icons.smart_toy,
                  label: 'Ask AI',
                  onTap: () => context.goNamed(RouteNames.aiAssistant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
