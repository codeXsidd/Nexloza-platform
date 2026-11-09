import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../devices/domain/entities/device_entity.dart';
import '../../domain/entities/simulation_profile.dart';
import '../../domain/entities/simulator_state.dart';
import '../providers/virtual_device_provider.dart';

class VirtualDevicesScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String organizationId;

  const VirtualDevicesScreen({
    super.key,
    required this.projectId,
    required this.organizationId,
  });

  @override
  ConsumerState<VirtualDevicesScreen> createState() =>
      _VirtualDevicesScreenState();
}

class _VirtualDevicesScreenState extends ConsumerState<VirtualDevicesScreen> {
  bool _showSearch = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(virtualDevicesProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search virtual devices...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Virtual Devices'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _searchQuery = '';
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
          '/virtual-devices/create?projectId=${widget.projectId}&organizationId=${widget.organizationId}',
        ),
        child: const Icon(Icons.add),
      ),
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error loading virtual devices',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () =>
                    ref.invalidate(virtualDevicesProvider(widget.projectId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (devices) {
          final filtered = _searchQuery.isEmpty
              ? devices
              : devices
                    .where(
                      (d) => d.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.devices_other,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No virtual devices',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a virtual device to start simulating IoT data',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.push(
                        '/virtual-devices/create?projectId=${widget.projectId}&organizationId=${widget.organizationId}',
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Virtual Device'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(virtualDevicesProvider(widget.projectId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) => _VirtualDeviceCard(
                device: filtered[index],
                projectId: widget.projectId,
                organizationId: widget.organizationId,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VirtualDeviceCard extends ConsumerWidget {
  final Device device;
  final String projectId;
  final String organizationId;

  const _VirtualDeviceCard({
    required this.device,
    required this.projectId,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileType = SimulationProfileType.fromString(
      device.simulationProfile ?? 'smart_home',
    );
    final simStateAsync = ref.watch(simulatorStateProvider(device.id));
    final simStatus = simStateAsync.valueOrNull?.status ?? SimulatorStatus.idle;

    final borderColor = switch (simStatus) {
      SimulatorStatus.running => Colors.green,
      SimulatorStatus.paused => Colors.orange,
      _ => theme.colorScheme.outlineVariant,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push(
          '/virtual-devices/${device.id}/simulator'
          '?projectId=$projectId'
          '&organizationId=$organizationId'
          '&profile=${device.simulationProfile ?? 'smart_home'}',
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: borderColor, width: 4)),
          ),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    profileType.icon,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(device.name),
                subtitle: Text('${profileType.displayName} • Virtual'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'VIRTUAL',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) => _onMenuAction(context, ref, value),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'simulator',
                          child: ListTile(
                            leading: Icon(Icons.play_circle_outline),
                            title: Text('Simulator'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'twin',
                          child: ListTile(
                            leading: Icon(Icons.compare_arrows),
                            title: Text('Digital Twin'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
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
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: device.isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      device.isOnline ? 'Online' : 'Offline',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    if (device.lastSeenAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• Last seen ${_formatTimestamp(device.lastSeenAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (simStatus == SimulatorStatus.running)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sensors,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Simulating',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    if (simStatus == SimulatorStatus.paused)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pause_circle_outline,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Paused',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'simulator':
        context.push(
          '/virtual-devices/${device.id}/simulator'
          '?projectId=$projectId'
          '&organizationId=$organizationId'
          '&profile=${device.simulationProfile ?? 'smart_home'}',
        );
      case 'twin':
        context.push(
          '/virtual-devices/${device.id}/twin'
          '?projectId=$projectId',
        );
      case 'delete':
        _confirmDelete(context, ref);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Virtual Device'),
        content: Text('Delete "${device.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(virtualDeviceControllerProvider)
                  .deleteVirtualDevice(device.id);
              ref.invalidate(virtualDevicesProvider(projectId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Virtual device deleted')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
