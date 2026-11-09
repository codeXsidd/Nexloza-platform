import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../theme/app_spacing.dart';
import '../../../devices/presentation/providers/device_provider.dart';
import '../../domain/entities/project_entity.dart';
import '../providers/project_provider.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(projectDetailProvider(projectId));
    final devicesAsync = ref.watch(projectDevicesProvider(projectId));
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

        final devices = devicesAsync.valueOrNull ?? [];
        final onlineCount = devices.where((d) => d.isOnline).length;

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
                  if (value == 'archive') {
                    final success = await ref
                        .read(projectsProvider.notifier)
                        .updateProject(project.id, {
                          'is_active': !project.isActive,
                        });
                    if (success && context.mounted) {
                      ref.invalidate(projectDetailProvider(projectId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            project.isActive
                                ? 'Project archived'
                                : 'Project restored',
                          ),
                        ),
                      );
                    }
                  } else if (value == 'delete') {
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
                  PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                      leading: Icon(
                        project.isActive
                            ? Icons.archive_outlined
                            : Icons.unarchive_outlined,
                      ),
                      title: Text(project.isActive ? 'Archive' : 'Restore'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(projectDetailProvider(projectId));
              ref.invalidate(projectDevicesProvider(projectId));
            },
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
                                Project.categoryIcon(project.category),
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
                            StatusBadge(
                              label: project.isActive ? 'Active' : 'Archived',
                              type: project.isActive
                                  ? StatusType.online
                                  : StatusType.offline,
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
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.devices_other,
                        label: 'Devices',
                        value: '${devices.length}',
                        theme: theme,
                      ),
                    ),
                    AppSpacing.horizontalSm,
                    Expanded(
                      child: _StatCard(
                        icon: Icons.wifi,
                        label: 'Online',
                        value: '$onlineCount',
                        color: const Color(0xFF4CAF50),
                        theme: theme,
                      ),
                    ),
                    AppSpacing.horizontalSm,
                    Expanded(
                      child: _StatCard(
                        icon: Icons.wifi_off,
                        label: 'Offline',
                        value: '${devices.length - onlineCount}',
                        color: Colors.grey,
                        theme: theme,
                      ),
                    ),
                  ],
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
                          label: 'Updated',
                          value:
                              '${project.updatedAt.day}/${project.updatedAt.month}/${project.updatedAt.year}',
                        ),
                        _DetailRow(
                          label: 'Status',
                          value: project.isActive ? 'Active' : 'Archived',
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.verticalMd,
                FilledButton.icon(
                  onPressed: () => context.pushNamed(RouteNames.devices),
                  icon: const Icon(Icons.devices_other),
                  label: const Text('View Devices'),
                ),
                AppSpacing.verticalSm,
                OutlinedButton.icon(
                  onPressed: () => context.pushNamed(RouteNames.addDevice),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Device'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final ThemeData theme;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color ?? theme.colorScheme.primary, size: 24),
            AppSpacing.verticalXs,
            Text(value, style: theme.textTheme.headlineSmall),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
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
