import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../theme/app_spacing.dart';
import '../../data/command_repository.dart';
import '../../domain/entities/actuator_entity.dart';
import '../../domain/entities/device_command_entity.dart';
import '../../domain/entities/sensor_entity.dart';
import '../../domain/entities/telemetry_entity.dart';
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
    final sensorsAsync = ref.watch(deviceSensorsProvider(deviceId));
    final actuatorsAsync = ref.watch(deviceActuatorsProvider(deviceId));
    final telemetryAsync = ref.watch(latestTelemetryProvider(deviceId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: deviceAsync.when(
          data: (d) => Text(d?.name ?? 'Device'),
          loading: () => const Text('Device'),
          error: (_, __) => const Text('Device'),
        ),
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
      ),
      body: deviceAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(deviceDetailProvider(deviceId)),
        ),
        data: (device) {
          if (device == null) {
            return const Center(child: Text('Device not found'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(deviceDetailProvider(deviceId));
              ref.invalidate(latestTelemetryProvider(deviceId));
              ref.invalidate(deviceSensorsProvider(deviceId));
              ref.invalidate(deviceActuatorsProvider(deviceId));
            },
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                _DeviceInfoCard(device: device, theme: theme),
                AppSpacing.verticalMd,
                _TelemetrySection(telemetryAsync: telemetryAsync, theme: theme),
                AppSpacing.verticalMd,
                _SensorsSection(
                  sensorsAsync: sensorsAsync,
                  telemetryAsync: telemetryAsync,
                  theme: theme,
                ),
                AppSpacing.verticalMd,
                _ActuatorsSection(
                  actuatorsAsync: actuatorsAsync,
                  deviceId: deviceId,
                  theme: theme,
                ),
                AppSpacing.verticalMd,
                _CommandSection(deviceId: deviceId, theme: theme),
                AppSpacing.verticalXl,
              ],
            ),
          );
        },
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
                  title: Text(c.apiKey, style: const TextStyle(fontSize: 12)),
                  subtitle: Text(
                    'Active: ${c.isActive} • Created: ${c.createdAt.toLocal().toString().substring(0, 16)}',
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
              label: const Text('Generate New Credentials'),
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
        title: const Text('New Credentials Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save these credentials now. The secret will not be shown again.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('API Key:'),
            SelectableText(apiKey, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            const Text('API Secret:'),
            SelectableText(apiSecret, style: const TextStyle(fontSize: 12)),
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

class _DeviceInfoCard extends StatelessWidget {
  final dynamic device;
  final ThemeData theme;

  const _DeviceInfoCard({required this.device, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                      Text(device.name, style: theme.textTheme.titleLarge),
                      AppSpacing.verticalXs,
                      StatusBadge(
                        label: device.isOnline ? 'Online' : 'Offline',
                        type: device.isOnline
                            ? StatusType.online
                            : StatusType.offline,
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
              _InfoRow('Firmware', device.firmwareVersion!),
            if (device.macAddress != null) _InfoRow('MAC', device.macAddress!),
            if (device.lastSeenAt != null)
              _InfoRow(
                'Last seen',
                device.lastSeenAt!.toLocal().toString().substring(0, 19),
              ),
          ],
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _TelemetrySection extends StatelessWidget {
  final AsyncValue<Map<String, TelemetryReading>> telemetryAsync;
  final ThemeData theme;

  const _TelemetrySection({required this.telemetryAsync, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Live Telemetry', style: theme.textTheme.titleMedium),
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
      ],
    );
  }
}

class _SensorsSection extends StatelessWidget {
  final AsyncValue<List<SensorDefinition>> sensorsAsync;
  final AsyncValue<Map<String, TelemetryReading>> telemetryAsync;
  final ThemeData theme;

  const _SensorsSection({
    required this.sensorsAsync,
    required this.telemetryAsync,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sensors', style: theme.textTheme.titleMedium),
        AppSpacing.verticalSm,
        sensorsAsync.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (sensors) {
            if (sensors.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: Text(
                      'No sensors configured',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              );
            }
            final readings = telemetryAsync.valueOrNull ?? {};
            return Column(
              children: sensors.map((sensor) {
                final reading = readings[sensor.telemetryKey];
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: Icon(
                      Icons.sensors,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(sensor.name),
                    subtitle: Text(
                      '${sensor.sensorType.displayName} • ${sensor.telemetryKey}',
                    ),
                    trailing: reading != null
                        ? Text(
                            '${reading.displayValue}${sensor.unit != null ? ' ${sensor.unit}' : ''}',
                            style: theme.textTheme.titleMedium,
                          )
                        : Text('--', style: theme.textTheme.titleMedium),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ActuatorsSection extends ConsumerWidget {
  final AsyncValue<List<ActuatorDefinition>> actuatorsAsync;
  final String deviceId;
  final ThemeData theme;

  const _ActuatorsSection({
    required this.actuatorsAsync,
    required this.deviceId,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actuators', style: theme.textTheme.titleMedium),
        AppSpacing.verticalSm,
        actuatorsAsync.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (actuators) {
            if (actuators.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: Text(
                      'No actuators configured',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: actuators.map((actuator) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: Icon(
                      Icons.settings_input_component,
                      color: theme.colorScheme.secondary,
                    ),
                    title: Text(actuator.name),
                    subtitle: Text(actuator.actuatorType.displayName),
                    trailing: _buildControl(context, ref, actuator),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildControl(
    BuildContext context,
    WidgetRef ref,
    ActuatorDefinition actuator,
  ) {
    if (actuator.controlType == ControlType.toggle) {
      return Switch(
        value: actuator.isOn,
        onChanged: (value) {
          ref
              .read(commandRepositoryProvider)
              .sendCommand(
                deviceId: deviceId,
                commandType: actuator.commandKey,
                payload: {'value': value},
              );
        },
      );
    }
    return FilledButton.tonal(
      onPressed: () => _showCommandDialog(context, ref, actuator),
      child: const Text('Control'),
    );
  }

  void _showCommandDialog(
    BuildContext context,
    WidgetRef ref,
    ActuatorDefinition actuator,
  ) {
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
                      payload: {'value': value},
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

class _CommandSection extends ConsumerWidget {
  final String deviceId;
  final ThemeData theme;

  const _CommandSection({required this.deviceId, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandsAsync = ref.watch(deviceCommandsProvider(deviceId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Commands', style: theme.textTheme.titleMedium),
            TextButton.icon(
              onPressed: () => _showSendCommandDialog(context, ref),
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Send'),
            ),
          ],
        ),
        commandsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text('Error: $e'),
          data: (commands) {
            if (commands.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: Text(
                      'No commands sent',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: commands.take(5).map((cmd) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      cmd.status.isTerminal
                          ? (cmd.status == CommandStatus.executed
                                ? Icons.check_circle
                                : Icons.error)
                          : Icons.schedule,
                      color: cmd.status == CommandStatus.executed
                          ? const Color(0xFF4CAF50)
                          : cmd.status == CommandStatus.failed
                          ? Colors.red
                          : null,
                      size: 20,
                    ),
                    title: Text(cmd.commandType),
                    subtitle: Text(cmd.status.displayName),
                    trailing: Text(
                      cmd.createdAt.toLocal().toString().substring(11, 19),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

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
