import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.projects),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: const EmptyStateWidget(
        icon: Icons.folder_outlined,
        title: AppStrings.noProjects,
        subtitle: AppStrings.noProjectsHint,
        actionLabel: AppStrings.newProject,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.createProject),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newProject),
      ),
    );
  }
}
