import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/project_provider.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(projectDetailProvider(projectId));
    final theme = Theme.of(context);

    return detailAsync.when(
      loading: () =>
          const Scaffold(body: LoadingIndicator(message: 'Loading project...')),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Project Details')),
        body: AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(projectDetailProvider(projectId)),
        ),
      ),
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Project Details')),
            body: const AppErrorWidget(message: 'Project not found'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => context.pushNamed(
                  RouteNames.editProject,
                  pathParameters: {'id': project.id},
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirmed = await showConfirmationDialog(
                      context,
                      title: 'Delete Project',
                      message:
                          'Are you sure you want to delete "${project.name}"? This will also delete all devices and data.',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                    if (confirmed) {
                      final success = await ref
                          .read(projectsProvider.notifier)
                          .deleteProject(project.id);
                      if (context.mounted) {
                        if (success) {
                          context.pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to delete project'),
                            ),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(projectDetailProvider(projectId)),
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              radius: 28,
                              child: Icon(
                                Icons.folder,
                                size: 28,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            AppSpacing.horizontalMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project.name,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  if (project.category != null)
                                    Text(
                                      project.category!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(
                                project.isActive ? 'Active' : 'Inactive',
                              ),
                              backgroundColor: project.isActive
                                  ? Colors.green.withAlpha(30)
                                  : Colors.grey.withAlpha(30),
                            ),
                          ],
                        ),
                        if (project.description != null) ...[
                          AppSpacing.verticalMd,
                          Text(
                            project.description!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                AppSpacing.verticalMd,
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Details', style: theme.textTheme.titleMedium),
                        AppSpacing.verticalMd,
                        _DetailRow(
                          label: 'Created',
                          value:
                              '${project.createdAt.day}/${project.createdAt.month}/${project.createdAt.year}',
                        ),
                        _DetailRow(
                          label: 'Devices',
                          value: '${project.deviceCount}',
                        ),
                        _DetailRow(
                          label: 'Status',
                          value: project.isActive ? 'Active' : 'Inactive',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
