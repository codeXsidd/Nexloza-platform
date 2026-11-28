import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../devices/presentation/providers/device_provider.dart';
import '../../../devices/presentation/providers/telemetry_provider.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../data/simulator_engine.dart';
import '../../data/telemetry_publisher.dart';
import '../../domain/entities/simulation_profile.dart';
import '../../domain/entities/simulator_state.dart';
import '../providers/virtual_device_provider.dart';

class SimulatorControlScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final String projectId;
  final String organizationId;
  final String profileType;

  const SimulatorControlScreen({
    super.key,
    required this.deviceId,
    required this.projectId,
    required this.organizationId,
    this.profileType = 'smart_home',
  });

  @override
  ConsumerState<SimulatorControlScreen> createState() =>
      _SimulatorControlScreenState();
}

class _SimulatorControlScreenState
    extends ConsumerState<SimulatorControlScreen> {
  final Map<FaultScenario, String?> _selectedFaultSensors = {};
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final simState = ref.watch(simulatorStateProvider(widget.deviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulator Control'),
        actions: [
          _SpeedDropdown(
            deviceId: widget.deviceId,
            currentSpeed: simState.valueOrNull?.speed ?? 1.0,
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _onMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.restart_alt),
                  title: Text('Reset to Initial'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'twin',
                child: ListTile(
                  leading: Icon(Icons.account_tree),
                  title: Text('Open Digital Twin'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: simState.when(
        data: (state) => _buildBody(context, theme, state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildBody(context, theme, null),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    SimulatorDeviceState? state,
  ) {
    final status = state?.status ?? SimulatorStatus.idle;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusCard(status: status, state: state, theme: theme),
          Text(
            ref.watch(simulatorDeliveryProvider(widget.deviceId)).valueOrNull ??
                'Waiting for telemetry status',
          ),
          if (status == SimulatorStatus.idle ||
              status == SimulatorStatus.stopped)
            OutlinedButton(
              onPressed: _starting ? null : _startMqtt,
              child: const Text('Start with MQTT'),
            ),
          const SizedBox(height: 16),
          _ControlButtons(
            status: status,
            onStart: _onStart,
            onPause: _onPause,
            onResume: _onResume,
            onStop: _onStop,
          ),
          const SizedBox(height: 16),
          ref
              .watch(telemetryStreamProvider(widget.deviceId))
              .when(
                data: (readings) {
                  if (readings.isEmpty) {
                    return const Text('No stored readings yet');
                  }
                  final reading = readings.firstWhere(
                    (reading) => reading.sensorKey == 'temperature',
                    orElse: () => readings.first,
                  );
                  return Text(
                    'Stored ${reading.sensorKey}: ${reading.value}\n'
                    '${reading.recordedAt.toUtc().toIso8601String()}'
                    '${reading.messageId == null ? '' : '\n${reading.messageId}'}',
                  );
                },
                loading: () => const Text('Loading stored telemetry'),
                error: (_, __) => const Text('Unable to read stored telemetry'),
              ),
          _SensorValuesCard(
            state: state,
            deviceId: widget.deviceId,
            profileType: widget.profileType,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _FaultScenariosCard(
            state: state,
            deviceId: widget.deviceId,
            selectedSensors: _selectedFaultSensors,
            onSensorSelected: (fault, sensor) {
              setState(() => _selectedFaultSensors[fault] = sensor);
            },
            theme: theme,
          ),
        ],
      ),
    );
  }

  Future<void> _startMqtt() async {
    var key = '';
    var secret = '';
    final credentials = await showDialog<({String username, String password})>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device MQTT credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Device API key'),
              onChanged: (value) => key = value.trim(),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Device API secret'),
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (value) => secret = value,
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
              if (key.isNotEmpty && secret.isNotEmpty) {
                Navigator.pop(context, (username: key, password: secret));
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    if (credentials != null && mounted) await _onStart(credentials);
  }

  Future<void> _onStart([
    ({String username, String password})? credentials,
  ]) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final device = await ref.read(
        deviceDetailProvider(widget.deviceId).future,
      );
      if (!mounted) return;
      final project = device == null
          ? null
          : await ref.read(projectDetailProvider(device.projectId).future);
      if (!mounted) return;
      if (project == null || device == null || !device.isVirtual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot resolve the virtual device project'),
          ),
        );
        return;
      }
      await ref
          .read(virtualDeviceControllerProvider)
          .startSimulation(
            deviceId: device.id,
            projectId: project.id,
            organizationId: project.organizationId ?? 'default',
            profileType: SimulationProfileType.fromString(widget.profileType),
            credentials: credentials,
          );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _onPause() {
    ref.read(virtualDeviceControllerProvider).pauseSimulation(widget.deviceId);
  }

  void _onResume() {
    ref.read(virtualDeviceControllerProvider).resumeSimulation(widget.deviceId);
  }

  void _onStop() {
    ref.read(virtualDeviceControllerProvider).stopSimulation(widget.deviceId);
  }

  void _onMenuAction(String action) {
    switch (action) {
      case 'reset':
        ref
            .read(virtualDeviceControllerProvider)
            .resetSimulation(widget.deviceId);
      case 'twin':
        context.push('/virtual-devices/${widget.deviceId}/twin');
    }
  }
}

class _SpeedDropdown extends ConsumerWidget {
  final String deviceId;
  final double currentSpeed;

  const _SpeedDropdown({required this.deviceId, required this.currentSpeed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<double>(
      tooltip: 'Simulation Speed',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed),
            const SizedBox(width: 4),
            Text('${currentSpeed}x'),
          ],
        ),
      ),
      onSelected: (speed) {
        ref.read(virtualDeviceControllerProvider).setSpeed(deviceId, speed);
      },
      itemBuilder: (context) => [
        for (final speed in [0.5, 1.0, 2.0, 5.0, 10.0])
          PopupMenuItem(
            value: speed,
            child: Text('${speed}x${speed == currentSpeed ? ' ✓' : ''}'),
          ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SimulatorStatus status;
  final SimulatorDeviceState? state;
  final ThemeData theme;

  const _StatusCard({
    required this.status,
    required this.state,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _StatusChip(status: status),
            const SizedBox(width: 12),
            if (state != null) ...[
              Icon(Icons.speed, size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
              Text('${state!.speed}x', style: theme.textTheme.bodyMedium),
              const SizedBox(width: 16),
              Icon(Icons.timer, size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
              Text('${state!.intervalMs}ms', style: theme.textTheme.bodyMedium),
            ],
            const Spacer(),
            if (state?.startedAt != null && status == SimulatorStatus.running)
              _ElapsedTime(startedAt: state!.startedAt!),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SimulatorStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      SimulatorStatus.running => (Colors.green, Icons.play_circle),
      SimulatorStatus.paused => (Colors.orange, Icons.pause_circle),
      SimulatorStatus.stopped => (Colors.red, Icons.stop_circle),
      SimulatorStatus.idle => (Colors.grey, Icons.circle_outlined),
    };

    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(status.displayName),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }
}

class _ElapsedTime extends StatelessWidget {
  final DateTime startedAt;

  const _ElapsedTime({required this.startedAt});

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(startedAt);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return Text(
      '${minutes}m ${seconds}s',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final SimulatorStatus status;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const _ControlButtons({
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = status == SimulatorStatus.running;
    final isPaused = status == SimulatorStatus.paused;
    final canStop = isRunning || isPaused;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (!isRunning && !isPaused)
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
          )
        else
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
          ),
        OutlinedButton.icon(
          onPressed: isRunning ? onPause : null,
          icon: const Icon(Icons.pause),
          label: const Text('Pause'),
        ),
        if (isPaused)
          FilledButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
          )
        else
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
          ),
        OutlinedButton.icon(
          onPressed: canStop ? onStop : null,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
          style: canStop
              ? OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
        ),
      ],
    );
  }
}

class _SensorValuesCard extends ConsumerWidget {
  final SimulatorDeviceState? state;
  final String deviceId;
  final String profileType;
  final ThemeData theme;

  const _SensorValuesCard({
    required this.state,
    required this.deviceId,
    required this.profileType,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = SimulationProfiles.forType(
      SimulationProfileType.fromString(profileType),
    );
    final sensors = state?.sensors ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sensor Values', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${sensors.length} sensors configured',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(),
            if (sensors.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Start simulation to see values',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              )
            else
              for (final entry in sensors.entries)
                _SensorRow(
                  sensorKey: entry.key,
                  sensorState: entry.value,
                  unit: _unitForKey(entry.key, profile),
                  deviceId: deviceId,
                  theme: theme,
                ),
          ],
        ),
      ),
    );
  }

  String _unitForKey(String key, SimulationProfile profile) {
    for (final s in profile.sensors) {
      if (s.telemetryKey == key) return s.unit;
    }
    return '';
  }
}

class _SensorRow extends ConsumerWidget {
  final String sensorKey;
  final SimulatedSensorState sensorState;
  final String unit;
  final String deviceId;
  final ThemeData theme;

  const _SensorRow({
    required this.sensorKey,
    required this.sensorState,
    required this.unit,
    required this.deviceId,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valueText = sensorState.currentValue.toStringAsFixed(
      sensorState.currentValue == sensorState.currentValue.roundToDouble()
          ? 0
          : 1,
    );

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.sensors,
        color: sensorState.isEnabled
            ? theme.colorScheme.primary
            : theme.colorScheme.outline,
      ),
      title: Row(
        children: [
          Expanded(child: Text(sensorKey)),
          if (sensorState.activeFault != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'FAULT',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$valueText $unit',
            style: theme.textTheme.titleSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 24,
            child: Switch(
              value: sensorState.isEnabled,
              onChanged: (enabled) {
                ref
                    .read(simulatorEngineProvider)
                    .setSensorEnabled(deviceId, sensorKey, enabled);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FaultScenariosCard extends ConsumerWidget {
  final SimulatorDeviceState? state;
  final String deviceId;
  final Map<FaultScenario, String?> selectedSensors;
  final void Function(FaultScenario, String?) onSensorSelected;
  final ThemeData theme;

  const _FaultScenariosCard({
    required this.state,
    required this.deviceId,
    required this.selectedSensors,
    required this.onSensorSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorKeys = state?.sensors.keys.toList() ?? <String>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fault Injection', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Simulate device and sensor failures for testing',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(),
            for (final fault in FaultScenario.values)
              ExpansionTile(
                leading: Icon(
                  Icons.warning_amber,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                title: Text(fault.displayName),
                subtitle: Text(
                  fault.description,
                  style: theme.textTheme.bodySmall,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedSensors[fault],
                            decoration: const InputDecoration(
                              labelText: 'Target Sensor',
                              isDense: true,
                            ),
                            items: [
                              if (fault == FaultScenario.deviceOffline)
                                const DropdownMenuItem(
                                  value: '_all',
                                  child: Text('All Sensors'),
                                ),
                              for (final key in sensorKeys)
                                DropdownMenuItem(value: key, child: Text(key)),
                            ],
                            onChanged: (val) => onSensorSelected(fault, val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _FaultToggleButton(
                          fault: fault,
                          sensorKey: selectedSensors[fault],
                          deviceId: deviceId,
                          state: state,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  'Fault scenarios are for testing only',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FaultToggleButton extends ConsumerWidget {
  final FaultScenario fault;
  final String? sensorKey;
  final String deviceId;
  final SimulatorDeviceState? state;

  const _FaultToggleButton({
    required this.fault,
    required this.sensorKey,
    required this.deviceId,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = _isFaultActive();
    final controller = ref.read(virtualDeviceControllerProvider);

    return FilledButton.tonal(
      onPressed: sensorKey == null
          ? null
          : () {
              if (isActive) {
                final targetKey = sensorKey == '_all'
                    ? state!.sensors.keys.first
                    : sensorKey!;
                controller.disableFault(deviceId, targetKey);
              } else {
                if (sensorKey == '_all') {
                  for (final key in state!.sensors.keys) {
                    controller.enableFault(deviceId, key, fault);
                  }
                } else {
                  controller.enableFault(deviceId, sensorKey!, fault);
                }
              }
            },
      style: isActive
          ? FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            )
          : null,
      child: Text(isActive ? 'Disable' : 'Enable'),
    );
  }

  bool _isFaultActive() {
    if (state == null || sensorKey == null) return false;
    if (sensorKey == '_all') {
      return state!.sensors.values.any((s) => s.activeFault == fault);
    }
    return state!.sensors[sensorKey]?.activeFault == fault;
  }
}
