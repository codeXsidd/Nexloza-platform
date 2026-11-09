import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../devices/presentation/providers/device_provider.dart';
import '../../../devices/presentation/providers/sensor_provider.dart';
import '../../../devices/presentation/providers/actuator_provider.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../domain/entities/data_source.dart';

class DataSourceSelector extends ConsumerStatefulWidget {
  final DataSource dataSource;
  final ValueChanged<DataSource> onChanged;

  const DataSourceSelector({
    super.key,
    required this.dataSource,
    required this.onChanged,
  });

  @override
  ConsumerState<DataSourceSelector> createState() => _DataSourceSelectorState();
}

class _DataSourceSelectorState extends ConsumerState<DataSourceSelector> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        projectsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => Text(
            'Failed to load projects',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (projects) {
            return DropdownButtonFormField<String>(
              initialValue: widget.dataSource.projectId,
              decoration: const InputDecoration(
                labelText: 'Project',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                for (final p in projects)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => widget.onChanged(DataSource(projectId: v)),
            );
          },
        ),
        if (widget.dataSource.projectId != null) ...[
          const SizedBox(height: 8),
          _DeviceDropdown(
            projectId: widget.dataSource.projectId!,
            selectedDeviceId: widget.dataSource.deviceId,
            onChanged: (deviceId) => widget.onChanged(
              widget.dataSource.copyWith(deviceId: deviceId),
            ),
          ),
        ],
        if (widget.dataSource.hasDevice) ...[
          const SizedBox(height: 8),
          _SensorActuatorDropdown(
            deviceId: widget.dataSource.deviceId!,
            selectedSensor: widget.dataSource.sensorKey,
            selectedActuator: widget.dataSource.actuatorKey,
            onSensorChanged: (key) => widget.onChanged(
              DataSource(
                projectId: widget.dataSource.projectId,
                deviceId: widget.dataSource.deviceId,
                sensorKey: key,
                telemetryKey: key,
              ),
            ),
            onActuatorChanged: (key) => widget.onChanged(
              DataSource(
                projectId: widget.dataSource.projectId,
                deviceId: widget.dataSource.deviceId,
                actuatorKey: key,
                telemetryKey: key,
              ),
            ),
          ),
        ],
        if (widget.dataSource.isBound)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Chip(
              avatar: const Icon(Icons.check_circle, size: 16),
              label: Text(
                'Bound: ${widget.dataSource.effectiveKey}',
                style: theme.textTheme.labelSmall,
              ),
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
          ),
      ],
    );
  }
}

class _DeviceDropdown extends ConsumerWidget {
  final String projectId;
  final String? selectedDeviceId;
  final ValueChanged<String?> onChanged;

  const _DeviceDropdown({
    required this.projectId,
    required this.selectedDeviceId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(projectDevicesProvider(projectId));

    return devicesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Failed to load devices'),
      data: (devices) {
        return DropdownButtonFormField<String>(
          initialValue: devices.any((d) => d.id == selectedDeviceId)
              ? selectedDeviceId
              : null,
          decoration: const InputDecoration(labelText: 'Device', isDense: true),
          items: [
            const DropdownMenuItem(value: null, child: Text('None')),
            for (final d in devices)
              DropdownMenuItem(
                value: d.id,
                child: Row(
                  children: [
                    Icon(
                      d.isOnline ? Icons.circle : Icons.circle_outlined,
                      size: 10,
                      color: d.isOnline ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Text(d.name)),
                    if (d.isVirtual) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SIM',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontSize: 9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _SensorActuatorDropdown extends ConsumerWidget {
  final String deviceId;
  final String? selectedSensor;
  final String? selectedActuator;
  final ValueChanged<String?> onSensorChanged;
  final ValueChanged<String?> onActuatorChanged;

  const _SensorActuatorDropdown({
    required this.deviceId,
    required this.selectedSensor,
    required this.selectedActuator,
    required this.onSensorChanged,
    required this.onActuatorChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorsAsync = ref.watch(deviceSensorsProvider(deviceId));
    final actuatorsAsync = ref.watch(deviceActuatorsProvider(deviceId));

    return Column(
      children: [
        sensorsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (sensors) {
            if (sensors.isEmpty) return const SizedBox.shrink();
            return DropdownButtonFormField<String>(
              initialValue: sensors.any((s) => s.telemetryKey == selectedSensor)
                  ? selectedSensor
                  : null,
              decoration: const InputDecoration(
                labelText: 'Sensor',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                for (final s in sensors)
                  DropdownMenuItem(
                    value: s.telemetryKey,
                    child: Text('${s.name} (${s.telemetryKey})'),
                  ),
              ],
              onChanged: onSensorChanged,
            );
          },
        ),
        const SizedBox(height: 8),
        actuatorsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (actuators) {
            if (actuators.isEmpty) return const SizedBox.shrink();
            return DropdownButtonFormField<String>(
              initialValue:
                  actuators.any((a) => a.commandKey == selectedActuator)
                  ? selectedActuator
                  : null,
              decoration: const InputDecoration(
                labelText: 'Actuator',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                for (final a in actuators)
                  DropdownMenuItem(
                    value: a.commandKey,
                    child: Text('${a.name} (${a.commandKey})'),
                  ),
              ],
              onChanged: onActuatorChanged,
            );
          },
        ),
      ],
    );
  }
}
