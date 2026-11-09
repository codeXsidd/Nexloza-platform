import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/sensor_repository.dart';
import '../../domain/entities/sensor_entity.dart';
import '../providers/sensor_provider.dart';
import '../providers/telemetry_provider.dart';

class ManageSensorsScreen extends ConsumerWidget {
  final String deviceId;

  const ManageSensorsScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorsAsync = ref.watch(deviceSensorsProvider(deviceId));
    final telemetryAsync = ref.watch(latestTelemetryProvider(deviceId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Sensors')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Sensor'),
      ),
      body: sensorsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(deviceSensorsProvider(deviceId)),
        ),
        data: (sensors) {
          if (sensors.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.sensors_off,
              title: 'No Sensors',
              subtitle: 'Add sensors to start collecting data',
              actionLabel: 'Add Sensor',
              onAction: () => _showAddDialog(context, ref),
            );
          }
          final readings = telemetryAsync.valueOrNull ?? {};
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: sensors.length,
            itemBuilder: (context, index) {
              final sensor = sensors[index];
              final reading = readings[sensor.telemetryKey];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.sensors,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(sensor.name),
                  subtitle: Text(
                    '${sensor.sensorType.displayName} · ${sensor.telemetryKey}'
                    '${sensor.unit != null ? ' · ${sensor.unit}' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (reading != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            reading.displayValue,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showEditDialog(context, ref, sensor),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () => _confirmDelete(context, ref, sensor),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtl = TextEditingController();
    final keyCtl = TextEditingController();
    final unitCtl = TextEditingController();
    var selectedType = SensorType.temperature;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Sensor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keyCtl,
                  decoration: const InputDecoration(
                    labelText: 'Telemetry Key',
                    hintText: 'e.g. temperature',
                  ),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                TextField(
                  controller: unitCtl,
                  decoration: const InputDecoration(
                    labelText: 'Unit (optional)',
                    hintText: 'e.g. celsius',
                  ),
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
                if (nameCtl.text.trim().isEmpty || keyCtl.text.trim().isEmpty) {
                  return;
                }
                await ref
                    .read(sensorRepositoryProvider)
                    .createSensor(
                      deviceId: deviceId,
                      projectId: '',
                      name: nameCtl.text.trim(),
                      sensorType: selectedType.dbValue,
                      telemetryKey: keyCtl.text.trim(),
                      unit: unitCtl.text.trim().isEmpty
                          ? null
                          : unitCtl.text.trim(),
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

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    SensorDefinition sensor,
  ) {
    final nameCtl = TextEditingController(text: sensor.name);
    final unitCtl = TextEditingController(text: sensor.unit ?? '');
    final minCtl = TextEditingController(
      text: sensor.minValue?.toString() ?? '',
    );
    final maxCtl = TextEditingController(
      text: sensor.maxValue?.toString() ?? '',
    );
    final samplingCtl = TextEditingController(
      text: sensor.samplingIntervalMs > 0
          ? '${sensor.samplingIntervalMs ~/ 1000}'
          : '',
    );
    final warnHighCtl = TextEditingController(
      text: sensor.warningThresholdHigh?.toString() ?? '',
    );
    final warnLowCtl = TextEditingController(
      text: sensor.warningThresholdLow?.toString() ?? '',
    );
    final critHighCtl = TextEditingController(
      text: sensor.criticalThresholdHigh?.toString() ?? '',
    );
    final critLowCtl = TextEditingController(
      text: sensor.criticalThresholdLow?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${sensor.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Telemetry Key',
                  hintText: sensor.telemetryKey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: unitCtl,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: samplingCtl,
                decoration: const InputDecoration(
                  labelText: 'Sampling Interval (seconds)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minCtl,
                      decoration: const InputDecoration(labelText: 'Min'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: maxCtl,
                      decoration: const InputDecoration(labelText: 'Max'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Thresholds', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: warnLowCtl,
                      decoration: const InputDecoration(labelText: 'Warn Low'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: warnHighCtl,
                      decoration: const InputDecoration(labelText: 'Warn High'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: critLowCtl,
                      decoration: const InputDecoration(labelText: 'Crit Low'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: critHighCtl,
                      decoration: const InputDecoration(labelText: 'Crit High'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
              final updates = <String, dynamic>{};
              if (nameCtl.text.trim().isNotEmpty) {
                updates['name'] = nameCtl.text.trim();
              }
              if (unitCtl.text.trim().isNotEmpty) {
                updates['unit'] = unitCtl.text.trim();
              }
              final sampling = int.tryParse(samplingCtl.text);
              if (sampling != null) {
                updates['sampling_interval_ms'] = sampling * 1000;
              }
              final min = double.tryParse(minCtl.text);
              if (min != null) updates['min_value'] = min;
              final max = double.tryParse(maxCtl.text);
              if (max != null) updates['max_value'] = max;
              final wh = double.tryParse(warnHighCtl.text);
              if (wh != null) updates['warning_threshold_high'] = wh;
              final wl = double.tryParse(warnLowCtl.text);
              if (wl != null) updates['warning_threshold_low'] = wl;
              final ch = double.tryParse(critHighCtl.text);
              if (ch != null) updates['critical_threshold_high'] = ch;
              final cl = double.tryParse(critLowCtl.text);
              if (cl != null) updates['critical_threshold_low'] = cl;
              if (updates.isNotEmpty) {
                await ref
                    .read(sensorRepositoryProvider)
                    .updateSensor(sensor.id, updates);
                ref.invalidate(deviceSensorsProvider(deviceId));
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SensorDefinition sensor,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Sensor',
      message: 'Remove "${sensor.name}" from this device?',
      isDestructive: true,
    );
    if (confirmed) {
      await ref.read(sensorRepositoryProvider).deleteSensor(sensor.id);
      ref.invalidate(deviceSensorsProvider(deviceId));
    }
  }
}
