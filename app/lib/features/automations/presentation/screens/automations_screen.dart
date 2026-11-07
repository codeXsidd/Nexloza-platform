import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

class AutomationsScreen extends ConsumerWidget {
  const AutomationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.automations),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: const EmptyStateWidget(
        icon: Icons.auto_awesome_outlined,
        title: AppStrings.noAutomations,
        subtitle: AppStrings.noAutomationsHint,
        actionLabel: AppStrings.newAutomation,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.createAutomation),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newAutomation),
      ),
    );
  }
}
