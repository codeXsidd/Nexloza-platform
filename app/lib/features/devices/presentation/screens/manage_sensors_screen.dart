import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../theme/app_spacing.dart';
import '../../data/sensor_repository.dart';
import '../../domain/entities/sensor_entity.dart';
import '../providers/device_provider.dart';
import '../providers/sensor_provider.dart';

class ManageSensorsScreen extends ConsumerWidget {
  final String deviceId;

  const ManageSensorsScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorsAsync = ref.watch(deviceSensorsProvider(deviceId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Sensors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(deviceSensorsProvider(deviceId)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSensorDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: sensorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sensors) {
          if (sensors.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sensors_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.verticalMd,
                  Text(
                    'No sensors registered',
                    style: theme.textTheme.bodyLarge,
                  ),
                  AppSpacing.verticalSm,
                  Text(
                    'Tap + to add a sensor definition',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: sensors.length,
            itemBuilder: (context, index) =>
                _SensorTile(sensor: sensors[index], deviceId: deviceId),
          );
        },
      ),
    );
  }

  void _showAddSensorDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final keyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    SensorType selectedType = SensorType.temperature;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Sensor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(controller: nameCtrl, label: 'Sensor Name'),
                AppSpacing.verticalSm,
                AppTextField(
                  controller: keyCtrl,
                  label: 'Telemetry Key (e.g., temp_1)',
                ),
                AppSpacing.verticalSm,
                DropdownButtonFormField<SensorType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Sensor Type'),
                  items: SensorType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedType = v ?? selectedType),
                ),
                AppSpacing.verticalSm,
                AppTextField(
                  controller: unitCtrl,
                  label: 'Unit (e.g., °C, %, lux)',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    keyCtrl.text.trim().isEmpty) {
                  return;
                }
                final device = await ref.read(
                  deviceDetailProvider(deviceId).future,
                );
                if (device == null) return;
                final repo = ref.read(sensorRepositoryProvider);
                await repo.createSensor(
                  deviceId: deviceId,
                  projectId: device.projectId,
                  name: nameCtrl.text.trim(),
                  sensorType: selectedType.dbValue,
                  telemetryKey: keyCtrl.text.trim(),
                  unit: unitCtrl.text.trim().isEmpty
                      ? null
                      : unitCtrl.text.trim(),
                );
                ref.invalidate(deviceSensorsProvider(deviceId));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorTile extends ConsumerWidget {
  final SensorDefinition sensor;
  final String deviceId;

  const _SensorTile({required this.sensor, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.sensors, color: theme.colorScheme.primary),
        ),
        title: Text(sensor.name),
        subtitle: Text(
          '${sensor.sensorType.displayName} • Key: ${sensor.telemetryKey}'
          '${sensor.unit != null ? ' • ${sensor.unit}' : ''}',
        ),
        isThreeLine:
            sensor.warningThresholdLow != null ||
            sensor.criticalThresholdHigh != null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final confirmed = await showConfirmationDialog(
              context,
              title: 'Delete Sensor',
              message: 'Remove "${sensor.name}" from this device?',
              isDestructive: true,
            );
            if (confirmed) {
              final repo = ref.read(sensorRepositoryProvider);
              await repo.deleteSensor(sensor.id);
              ref.invalidate(deviceSensorsProvider(deviceId));
            }
          },
        ),
      ),
    );
  }
}
