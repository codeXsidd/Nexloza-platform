import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nexioza/features/projects/presentation/providers/project_provider.dart';
import 'package:nexioza/shared/widgets/nexioza_empty_state.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(projectsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool>('/projects/create');
          if (created == true) ref.invalidate(projectsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: projects.when(
        data: (list) {
          if (list.isEmpty) {
            return NexiozaEmptyState(
              icon: Icons.folder_outlined,
              title: 'No projects yet',
              message: 'Create your first IoT project to get started.',
              actionLabel: 'Create Project',
              onAction: () => context.push('/projects/create'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(projectsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final project = list[index];
                final colorHex = project['color'] as String? ?? '#0891B2';
                final color = Color(
                    int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(Icons.folder_rounded, color: color),
                    ),
                    title: Text(
                      project['name'] as String? ?? '',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      project['description'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Project detail coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(projectsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
