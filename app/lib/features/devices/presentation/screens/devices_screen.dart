import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/device_entity.dart';
import '../providers/device_provider.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  String _searchQuery = '';
  HardwarePlatform? _platformFilter;
  bool? _onlineFilter;

  @override
  Widget build(BuildContext context) {
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
          if (devices.isEmpty && _searchQuery.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.devices_other_outlined,
              title: 'No Devices',
              subtitle: 'Add your first IoT device to get started',
              actionLabel: 'Add Device',
              onAction: () => context.pushNamed(RouteNames.addDevice),
            );
          }

          final filtered = devices.where((d) {
            if (_searchQuery.isNotEmpty &&
                !d.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                !d.deviceType.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                )) {
              return false;
            }
            if (_platformFilter != null &&
                d.hardwarePlatform != _platformFilter) {
              return false;
            }
            if (_onlineFilter != null && d.isOnline != _onlineFilter) {
              return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search devices...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.inputRadius,
                      ),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  children: [
                    _chip(
                      'All',
                      _platformFilter == null && _onlineFilter == null,
                      () => setState(() {
                        _platformFilter = null;
                        _onlineFilter = null;
                      }),
                    ),
                    _chip(
                      'Online',
                      _onlineFilter == true,
                      () => setState(() {
                        _onlineFilter = _onlineFilter == true ? null : true;
                        _platformFilter = null;
                      }),
                    ),
                    _chip(
                      'ESP32',
                      _platformFilter == HardwarePlatform.esp32,
                      () => setState(() {
                        _platformFilter =
                            _platformFilter == HardwarePlatform.esp32
                            ? null
                            : HardwarePlatform.esp32;
                        _onlineFilter = null;
                      }),
                    ),
                    _chip(
                      'ESP8266',
                      _platformFilter == HardwarePlatform.esp8266,
                      () => setState(() {
                        _platformFilter =
                            _platformFilter == HardwarePlatform.esp8266
                            ? null
                            : HardwarePlatform.esp8266;
                        _onlineFilter = null;
                      }),
                    ),
                    _chip(
                      'RPi',
                      _platformFilter == HardwarePlatform.raspberryPi,
                      () => setState(() {
                        _platformFilter =
                            _platformFilter == HardwarePlatform.raspberryPi
                            ? null
                            : HardwarePlatform.raspberryPi;
                        _onlineFilter = null;
                      }),
                    ),
                    _chip(
                      'Arduino',
                      _platformFilter == HardwarePlatform.arduino,
                      () => setState(() {
                        _platformFilter =
                            _platformFilter == HardwarePlatform.arduino
                            ? null
                            : HardwarePlatform.arduino;
                        _onlineFilter = null;
                      }),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No devices match your filters',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(devicesProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _DeviceCard(
                            device: filtered[index],
                            theme: theme,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => context.push('/devices/${device.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
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
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name, style: theme.textTheme.titleSmall),
                    Row(
                      children: [
                        Text(
                          device.hardwarePlatform.displayName,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (device.firmwareVersion != null) ...[
                          Text(' · ', style: theme.textTheme.bodySmall),
                          Text(
                            'v${device.firmwareVersion}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                    if (device.lastSeenAt != null)
                      Text(
                        device.isOnline
                            ? 'Online'
                            : 'Last seen ${timeago.format(device.lastSeenAt!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: device.isOnline
                              ? const Color(0xFF4CAF50)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              StatusBadge(
                label: device.isOnline ? 'Online' : 'Offline',
                type: device.isOnline ? StatusType.online : StatusType.offline,
              ),
            ],
          ),
        ),
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
