import 'package:flutter/material.dart';

import 'package:nexioza/shared/widgets/nexioza_card.dart';
import 'package:nexioza/shared/widgets/nexioza_empty_state.dart';
import 'package:nexioza/shared/widgets/nexioza_section_header.dart';
import 'package:nexioza/shared/widgets/nexioza_stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Welcome to NexIoza',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your IoT command center',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 400 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.4,
                    children: const [
                      NexiozaStatCard(
                        label: 'Projects',
                        value: '0',
                        icon: Icons.folder_outlined,
                        iconColor: Color(0xFF6366F1),
                      ),
                      NexiozaStatCard(
                        label: 'Devices',
                        value: '0',
                        icon: Icons.devices_rounded,
                        iconColor: Color(0xFF0891B2),
                      ),
                      NexiozaStatCard(
                        label: 'Online',
                        value: '0',
                        icon: Icons.cloud_done_outlined,
                        iconColor: Color(0xFF16A34A),
                      ),
                      NexiozaStatCard(
                        label: 'Automations',
                        value: '0',
                        icon: Icons.bolt_rounded,
                        iconColor: Color(0xFFF59E0B),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              NexiozaCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_circle_outline_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create your first project',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start building your IoT solution',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Coming in Phase 2'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const NexiozaSectionHeader(title: 'Recent Activity'),
              const SizedBox(height: 48),
              const NexiozaEmptyState(
                icon: Icons.history_rounded,
                title: 'No recent activity',
                message:
                    'Activity from your projects and devices will appear here.',
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
