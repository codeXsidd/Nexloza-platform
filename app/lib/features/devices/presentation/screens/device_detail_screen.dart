import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/services/mqtt_service.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../theme/app_spacing.dart';
import '../../data/command_repository.dart';
import '../../domain/entities/actuator_entity.dart';
import '../../domain/entities/device_command_entity.dart';
import '../providers/actuator_provider.dart';
import '../providers/command_provider.dart';
import '../providers/device_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/telemetry_provider.dart';

class DeviceDetailScreen extends ConsumerWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(deviceDetailProvider(deviceId));

    return deviceAsync.when(
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Device')),
        body: AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(deviceDetailProvider(deviceId)),
        ),
      ),
      data: (device) {
        if (device == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Device')),
            body: const Center(child: Text('Device not found')),
          );
        }
        return _DeviceDetailBody(device: device, deviceId: deviceId);
      },
    );
  }
}

class _DeviceDetailBody extends ConsumerWidget {
  final dynamic device;
  final String deviceId;

  const _DeviceDetailBody({required this.device, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mqttStatus = ref.watch(mqttStatusProvider);
    ref.listen(commandStreamProvider(deviceId), (before, after) {
      final earlier = before?.valueOrNull ?? const <DeviceCommand>[];
      final current = after.valueOrNull ?? const <DeviceCommand>[];
      if (current.any(
        (command) =>
            command.status == CommandStatus.executed &&
            !earlier.any(
              (old) => old.id == command.id && old.status == command.status,
            ),
      )) {
        ref.invalidate(deviceActuatorsProvider(deviceId));
      }
    });

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(device.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/devices/$deviceId/edit'),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'credentials') {
                  _showCredentials(context, ref);
                } else if (value == 'sensors') {
                  context.push('/devices/$deviceId/sensors');
                } else if (value == 'actuators') {
                  context.push('/devices/$deviceId/actuators');
                } else if (value == 'delete') {
                  final confirmed = await showConfirmationDialog(
                    context,
                    title: 'Delete Device',
                    message: 'This will permanently delete this device and all its data.',
                    isDestructive: true,
                  );
                  if (confirmed && context.mounted) {
                    await ref
                        .read(devicesProvider.notifier)
                        .deleteDevice(deviceId);
                    if (context.mounted) context.pop();
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'credentials',
                  child: ListTile(
                    leading: Icon(Icons.key),
                    title: Text('Credentials'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'sensors',
                  child: ListTile(
                    leading: Icon(Icons.sensors),
                    title: Text('Manage Sensors'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'actuators',
                  child: ListTile(
                    leading: Icon(Icons.settings_input_component),
                    title: Text('Manage Actuators'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Sensors'),
              Tab(text: 'Actuators'),
              Tab(text: 'Commands'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(
              device: device,
              deviceId: deviceId,
              mqttStatus: mqttStatus,
            ),
            _SensorsTab(deviceId: deviceId),
            _ActuatorsTab(deviceId: deviceId),
            _CommandsTab(deviceId: deviceId),
          ],
        ),
      ),
    );
  }

  void _showCredentials(BuildContext context, WidgetRef ref) async {
    final creds = await ref.read(deviceCredentialsProvider(deviceId).future);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (creds.isEmpty)
              const Text('No credentials provisioned yet.')
            else
              ...creds.map(
                (c) => ListTile(
                  title: Text(
                    c.apiKey,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  subtitle: Text(
                    'Active: ${c.isActive} · Created: ${c.createdAt.toLocal().toString().substring(0, 16)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: c.apiKey));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API key copied')),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final result = await ref
                    .read(devicesProvider.notifier)
                    .provisionCredentials(deviceId);
                if (result != null && context.mounted) {
                  Navigator.pop(context);
                  _showNewCredential(context, result.apiKey, result.apiSecret);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Generate New'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNewCredential(
    BuildContext context,
    String apiKey,
    String apiSecret,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save these now. The secret will not be shown again.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('API Key:'),
            SelectableText(
              apiKey,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            const Text('API Secret:'),
            SelectableText(
              apiSecret,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: 'API_KEY=$apiKey\nAPI_SECRET=$apiSecret'),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Credentials copied')),
              );
            },
            child: const Text('Copy All'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final dynamic device;
  final String deviceId;
  final AsyncValue<MqttConnectionStatus> mqttStatus;

  const _OverviewTab({
    required this.device,
    required this.deviceId,
    required this.mqttStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(latestTelemetryProvider(deviceId));
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(deviceDetailProvider(deviceId));
        ref.invalidate(latestTelemetryProvider(deviceId));
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
                        backgroundColor: theme.colorScheme.primaryContainer,
                        radius: 28,
                        child: Icon(
                          Icons.memory,
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
                              device.name,
                              style: theme.textTheme.titleLarge,
                            ),
                            AppSpacing.verticalXs,
                            Row(
                              children: [
                                StatusBadge(
                                  label: device.isOnline ? 'Online' : 'Offline',
                                  type: device.isOnline
                                      ? StatusType.online
                                      : StatusType.offline,
                                ),
                                AppSpacing.horizontalSm,
                                if (device.isVirtual)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.colorScheme.tertiaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'VIRTUAL',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: theme
                                            .colorScheme
                                            .onTertiaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (!device.isVirtual)
                                  mqttStatus.when(
                                    data: (s) => _MqttBadge(status: s),
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalMd,
                  _InfoRow('Platform', device.hardwarePlatform.displayName),
                  _InfoRow('Type', device.deviceType),
                  if (device.firmwareVersion != null)
                    _InfoRow('Firmware', 'v${device.firmwareVersion}'),
                  if (device.macAddress != null)
                    _InfoRow('MAC', device.macAddress!),
                  if (device.lastSeenAt != null)
                    _InfoRow(
                      'Last seen',
                      device.isOnline
                          ? 'Now'
                          : timeago.format(device.lastSeenAt!),
                    ),
                  _InfoRow('Device ID', device.id),
                ],
              ),
            ),
          ),
          if (device.isVirtual) ...[
            AppSpacing.verticalSm,
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.push(
                      '/virtual-devices/$deviceId/simulator'
                      '?projectId=${device.projectId}'
                      '&organizationId=default'
                      '&profile=${device.simulationProfile ?? "smart_home"}',
                    ),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Simulator'),
                  ),
                ),
                AppSpacing.horizontalSm,
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/virtual-devices/$deviceId/twin'),
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('Digital Twin'),
                  ),
                ),
              ],
            ),
          ],
          if (!device.isOnline && device.lastSeenAt != null) ...[
            AppSpacing.verticalSm,
            Card(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: theme.colorScheme.error),
                    AppSpacing.horizontalSm,
                    Expanded(
                      child: Text(
                        'Device is offline. Data shown may be stale.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          AppSpacing.verticalMd,
          Text('Latest Telemetry', style: theme.textTheme.titleMedium),
          AppSpacing.verticalSm,
          telemetryAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Error: $e'),
              ),
            ),
            data: (readings) {
              if (readings.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Center(
                      child: Text(
                        'No telemetry data yet',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                );
              }
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: readings.entries.map((entry) {
                  return SizedBox(
                    width: 150,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          children: [
                            Text(entry.key, style: theme.textTheme.bodySmall),
                            AppSpacing.verticalXs,
                            Text(
                              entry.value.displayValue,
                              style: theme.textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          AppSpacing.verticalXl,
        ],
      ),
    );
  }
}

class _SensorsTab extends ConsumerWidget {
  final String deviceId;

  const _SensorsTab({required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorsAsync = ref.watch(deviceSensorsProvider(deviceId));
    final telemetryAsync = ref.watch(latestTelemetryProvider(deviceId));
    final theme = Theme.of(context);

    return sensorsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (sensors) {
        if (sensors.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sensors_off,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                AppSpacing.verticalMd,
                Text('No sensors configured', style: theme.textTheme.bodyLarge),
                AppSpacing.verticalSm,
                FilledButton.tonal(
                  onPressed: () => context.push('/devices/$deviceId/sensors'),
                  child: const Text('Add Sensors'),
                ),
              ],
            ),
          );
        }
        final readings = telemetryAsync.valueOrNull ?? {};
        return ListView.builder(
          padding: AppSpacing.screenPadding,
          itemCount: sensors.length + 1,
          itemBuilder: (context, index) {
            if (index == sensors.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/devices/$deviceId/sensors'),
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage Sensors'),
                ),
              );
            }
            final sensor = sensors[index];
            final reading = readings[sensor.telemetryKey];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.sensors,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    AppSpacing.horizontalMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sensor.name, style: theme.textTheme.titleSmall),
                          Text(
                            '${sensor.sensorType.displayName} · ${sensor.telemetryKey}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (sensor.unit != null)
                            Text(
                              'Unit: ${sensor.unit}',
                              style: theme.textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          reading != null
                              ? '${reading.displayValue}${sensor.unit != null ? ' ${sensor.unit}' : ''}'
                              : '--',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        StatusBadge(
                          label: sensor.isActive ? 'Active' : 'Inactive',
                          type: sensor.isActive
                              ? StatusType.online
                              : StatusType.offline,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ActuatorsTab extends ConsumerWidget {
  final String deviceId;

  const _ActuatorsTab({required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actuatorsAsync = ref.watch(deviceActuatorsProvider(deviceId));
    final theme = Theme.of(context);

    return actuatorsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (actuators) {
        if (actuators.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.settings_input_component,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                AppSpacing.verticalMd,
                Text(
                  'No actuators configured',
                  style: theme.textTheme.bodyLarge,
                ),
                AppSpacing.verticalSm,
                FilledButton.tonal(
                  onPressed: () => context.push('/devices/$deviceId/actuators'),
                  child: const Text('Add Actuators'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: AppSpacing.screenPadding,
          itemCount: actuators.length + 1,
          itemBuilder: (context, index) {
            if (index == actuators.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/devices/$deviceId/actuators'),
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage Actuators'),
                ),
              );
            }
            final actuator = actuators[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.settings_input_component,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    AppSpacing.horizontalMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            actuator.name,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            '${actuator.actuatorType.displayName} · ${actuator.controlType.displayName}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _ActuatorControl(actuator: actuator, deviceId: deviceId),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ActuatorControl extends ConsumerWidget {
  final ActuatorDefinition actuator;
  final String deviceId;

  const _ActuatorControl({required this.actuator, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (actuator.controlType == ControlType.toggle) {
      return Switch(
        value: actuator.isOn,
        onChanged: (value) {
          ref
              .read(commandRepositoryProvider)
              .sendCommand(
                deviceId: deviceId,
                commandType: actuator.commandKey,
                payload: {'value': value, 'actuator_id': actuator.id},
              );
        },
      );
    }
    return FilledButton.tonal(
      onPressed: () => _showCommandDialog(context, ref),
      child: const Text('Control'),
    );
  }

  void _showCommandDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: actuator.currentValue.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Control ${actuator.name}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Value (${actuator.minValue} - ${actuator.maxValue})',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                ref
                    .read(commandRepositoryProvider)
                    .sendCommand(
                      deviceId: deviceId,
                      commandType: actuator.commandKey,
                      payload: {'value': value, 'actuator_id': actuator.id},
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _CommandsTab extends ConsumerWidget {
  final String deviceId;

  const _CommandsTab({required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandsAsync = ref.watch(commandStreamProvider(deviceId));
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Command History', style: theme.textTheme.titleMedium),
              FilledButton.tonalIcon(
                onPressed: () => _showSendCommandDialog(context, ref),
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Send'),
              ),
            ],
          ),
        ),
        Expanded(
          child: commandsAsync.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => AppErrorWidget(message: e.toString()),
            data: (commands) {
              if (commands.isEmpty) {
                return Center(
                  child: Text(
                    'No commands sent yet',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }
              return ListView.builder(
                padding: AppSpacing.screenPadding,
                itemCount: commands.length,
                itemBuilder: (context, index) {
                  final cmd = commands[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        _commandIcon(cmd.status),
                        color: _commandColor(cmd.status),
                        size: 20,
                      ),
                      title: Text(cmd.commandType),
                      subtitle: Text(cmd.status.displayName),
                      trailing: Text(
                        timeago.format(cmd.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _commandIcon(CommandStatus status) => switch (status) {
    CommandStatus.executed => Icons.check_circle,
    CommandStatus.failed || CommandStatus.timeout => Icons.error,
    CommandStatus.pending || CommandStatus.sent => Icons.schedule,
    CommandStatus.acknowledged => Icons.done,
  };

  Color _commandColor(CommandStatus status) => switch (status) {
    CommandStatus.executed => const Color(0xFF4CAF50),
    CommandStatus.failed || CommandStatus.timeout => Colors.red,
    CommandStatus.acknowledged => Colors.blue,
    _ => Colors.grey,
  };

  void _showSendCommandDialog(BuildContext context, WidgetRef ref) {
    final typeController = TextEditingController();
    final payloadController = TextEditingController(text: '{}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Command'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: 'Command Type'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: payloadController,
              decoration: const InputDecoration(labelText: 'Payload (JSON)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final type = typeController.text.trim();
              if (type.isEmpty) return;
              Map<String, dynamic> payload = {};
              try {
                payload = jsonDecode(
                  payloadController.text.trim(),
                ) as Map<String, dynamic>;
              } catch (_) {}
              ref
                  .read(commandRepositoryProvider)
                  .sendCommand(
                    deviceId: deviceId,
                    commandType: type,
                    payload: payload,
                  );
              Navigator.pop(context);
              ref.invalidate(deviceCommandsProvider(deviceId));
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _MqttBadge extends StatelessWidget {
  final MqttConnectionStatus status;

  const _MqttBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MqttConnectionStatus.connected => ('MQTT', const Color(0xFF4CAF50)),
      MqttConnectionStatus.connecting => ('Connecting', Colors.orange),
      MqttConnectionStatus.disconnected => ('MQTT Off', Colors.grey),
      MqttConnectionStatus.error => ('MQTT Error', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
