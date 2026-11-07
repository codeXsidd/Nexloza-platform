import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../theme/app_spacing.dart';

class DeviceDetailScreen extends ConsumerWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Details'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'diagnostics', child: Text('Diagnostics')),
              const PopupMenuItem(value: 'firmware', child: Text('Update Firmware')),
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
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        radius: 28,
                        child: Icon(Icons.memory, size: 28, color: theme.colorScheme.primary),
                      ),
                      AppSpacing.horizontalMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Device $deviceId', style: theme.textTheme.titleLarge),
                            AppSpacing.verticalXs,
                            const StatusBadge(label: 'Offline', type: StatusType.offline),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.verticalMd,
          Text('Sensors', style: theme.textTheme.titleMedium),
          AppSpacing.verticalSm,
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Center(
                child: Text('No sensors configured', style: theme.textTheme.bodyMedium),
              ),
            ),
          ),
          AppSpacing.verticalMd,
          Text('Actuators', style: theme.textTheme.titleMedium),
          AppSpacing.verticalSm,
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Center(
                child: Text('No actuators configured', style: theme.textTheme.bodyMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
