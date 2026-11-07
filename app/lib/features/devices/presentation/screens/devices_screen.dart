import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.devices),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Text('Filter by status'),
              ),
              const PopupMenuItem(value: 'sort', child: Text('Sort by name')),
            ],
          ),
        ],
      ),
      body: const EmptyStateWidget(
        icon: Icons.devices_other_outlined,
        title: AppStrings.noDevices,
        subtitle: AppStrings.noDevicesHint,
        actionLabel: AppStrings.addDevice,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.addDevice),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addDevice),
      ),
    );
  }
}
