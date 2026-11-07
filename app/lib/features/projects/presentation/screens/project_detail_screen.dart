import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_spacing.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'members', child: Text('Members')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project ID: $projectId',
                    style: theme.textTheme.bodySmall,
                  ),
                  AppSpacing.verticalMd,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoTile(
                        icon: Icons.devices,
                        label: 'Devices',
                        value: '0',
                      ),
                      _InfoTile(
                        icon: Icons.sensors,
                        label: 'Sensors',
                        value: '0',
                      ),
                      _InfoTile(
                        icon: Icons.auto_awesome,
                        label: 'Automations',
                        value: '0',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.verticalMd,
          Text('Dashboards', style: theme.textTheme.titleMedium),
          AppSpacing.verticalSm,
          Card(
            child: ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Default Dashboard'),
              subtitle: const Text('0 widgets'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          AppSpacing.verticalMd,
          Text('Recent Telemetry', style: theme.textTheme.titleMedium),
          AppSpacing.verticalSm,
          const Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Center(child: Text('No telemetry data yet')),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
