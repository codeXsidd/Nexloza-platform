import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../providers/project_provider.dart';
import '../widgets/project_card.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.projects)),
      body: projectsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(projectsProvider),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.folder_outlined,
              title: AppStrings.noProjects,
              subtitle: AppStrings.noProjectsHint,
              actionLabel: AppStrings.newProject,
              onAction: () => context.pushNamed(RouteNames.createProject),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(projectsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return ProjectCard(
                  project: project,
                  onTap: () => context.pushNamed(
                    RouteNames.projectDetail,
                    pathParameters: {'id': project.id},
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.createProject),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newProject),
      ),
    );
  }
}
