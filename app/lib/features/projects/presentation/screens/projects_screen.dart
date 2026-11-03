import 'package:flutter/material.dart';

import 'package:nexioza/shared/widgets/nexioza_empty_state.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search coming in Phase 2'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: NexiozaEmptyState(
        icon: Icons.folder_outlined,
        title: 'No projects yet',
        message: 'Create your first IoT project to get started.',
        actionLabel: 'Create Project',
        onAction: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coming in Phase 2'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}
