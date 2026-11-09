import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/device_entity.dart';
import '../providers/device_provider.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(devicesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.addDevice),
        icon: const Icon(Icons.add),
        label: const Text('Add Device'),
      ),
      body: devicesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(devicesProvider),
        ),
        data: (devices) {
          if (devices.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.devices_other_outlined,
              title: 'No Devices',
              subtitle: 'Add your first IoT device to get started',
              actionLabel: 'Add Device',
              onAction: () => context.pushNamed(RouteNames.addDevice),
            );
          }
          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: devices.length,
            itemBuilder: (context, index) =>
                _DeviceCard(device: devices[index], theme: theme),
          );
        },
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final ThemeData theme;

  const _DeviceCard({required this.device, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.isOnline
              ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            _platformIcon(device.hardwarePlatform),
            color: device.isOnline
                ? const Color(0xFF4CAF50)
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(device.name),
        subtitle: Text(device.hardwarePlatform.displayName),
        trailing: StatusBadge(
          label: device.isOnline ? 'Online' : 'Offline',
          type: device.isOnline ? StatusType.online : StatusType.offline,
        ),
        onTap: () => context.push('/devices/${device.id}'),
      ),
    );
  }

  IconData _platformIcon(HardwarePlatform platform) => switch (platform) {
    HardwarePlatform.esp32 => Icons.memory,
    HardwarePlatform.esp8266 => Icons.memory,
    HardwarePlatform.raspberryPi => Icons.developer_board,
    HardwarePlatform.arduino => Icons.developer_board,
    HardwarePlatform.genericMqtt => Icons.router,
    HardwarePlatform.other => Icons.devices_other,
  };
}
