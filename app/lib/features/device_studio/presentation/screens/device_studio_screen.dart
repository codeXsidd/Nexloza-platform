import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_spacing.dart';
import '../../domain/board_definitions.dart';
import '../../domain/code_generator.dart';

class DeviceStudioScreen extends ConsumerStatefulWidget {
  const DeviceStudioScreen({super.key});

  @override
  ConsumerState<DeviceStudioScreen> createState() => _DeviceStudioScreenState();
}

class _DeviceStudioScreenState extends ConsumerState<DeviceStudioScreen> {
  int _step = 0;
  BoardDefinition? _selectedBoard;
  final List<SensorDefinition> _selectedSensors = [];
  final List<ActuatorDefinition> _selectedActuators = [];
  final Map<String, int> _pinAssignments = {};
  String? _generatedCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Studio'),
        actions: [
          if (_step > 0)
            TextButton(
              onPressed: () => setState(() => _step--),
              child: const Text('Back'),
            ),
        ],
      ),
      body: Stepper(
        currentStep: _step,
        onStepContinue: _onStepContinue,
        onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(_step == 3 ? 'Generate Code' : 'Continue'),
                ),
                if (_step > 0) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Select Board'),
            subtitle: _selectedBoard != null
                ? Text(_selectedBoard!.name)
                : null,
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
            content: _buildBoardSelection(theme),
          ),
          Step(
            title: const Text('Select Sensors'),
            subtitle: _selectedSensors.isNotEmpty
                ? Text('${_selectedSensors.length} selected')
                : null,
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
            content: _buildSensorSelection(theme),
          ),
          Step(
            title: const Text('Select Actuators'),
            subtitle: _selectedActuators.isNotEmpty
                ? Text('${_selectedActuators.length} selected')
                : null,
            isActive: _step >= 2,
            state: _step > 2 ? StepState.complete : StepState.indexed,
            content: _buildActuatorSelection(theme),
          ),
          Step(
            title: const Text('Pin Configuration'),
            isActive: _step >= 3,
            state: _step > 3 ? StepState.complete : StepState.indexed,
            content: _buildPinConfig(theme),
          ),
          Step(
            title: const Text('Generated Code'),
            isActive: _step >= 4,
            content: _buildCodeOutput(theme),
          ),
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_step == 0 && _selectedBoard == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a board')));
      return;
    }
    if (_step == 3) {
      _generateCode();
    }
    if (_step < 4) {
      setState(() => _step++);
    }
  }

  void _generateCode() {
    final config = FirmwareConfig(
      board: _selectedBoard!,
      sensors: _selectedSensors,
      actuators: _selectedActuators,
      pinAssignments: _pinAssignments,
    );
    _generatedCode = CodeGenerator.generate(config);
  }

  Widget _buildBoardSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: Boards.all.map((board) {
        final selected = _selectedBoard?.id == board.id;
        return Card(
          color: selected ? theme.colorScheme.primaryContainer : null,
          child: ListTile(
            leading: Icon(
              Icons.memory,
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.primary,
            ),
            title: Text(board.name),
            subtitle: Text(board.description),
            trailing: selected ? const Icon(Icons.check_circle) : null,
            onTap: () => setState(() => _selectedBoard = board),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSensorSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: Sensors.all.map((sensor) {
        final selected = _selectedSensors.contains(sensor);
        return CheckboxListTile(
          value: selected,
          title: Text(sensor.name),
          subtitle: Text(sensor.type),
          secondary: Icon(
            Icons.sensors,
            color: selected ? theme.colorScheme.primary : null,
          ),
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selectedSensors.add(sensor);
              } else {
                _selectedSensors.remove(sensor);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildActuatorSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: Actuators.all.map((actuator) {
        final selected = _selectedActuators.contains(actuator);
        return CheckboxListTile(
          value: selected,
          title: Text(actuator.name),
          subtitle: Text(actuator.type),
          secondary: Icon(
            Icons.settings_input_component,
            color: selected ? theme.colorScheme.primary : null,
          ),
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selectedActuators.add(actuator);
              } else {
                _selectedActuators.remove(actuator);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPinConfig(ThemeData theme) {
    if (_selectedBoard == null) return const Text('Select a board first');
    final pins = _selectedBoard!.gpioPins;
    final items = [
      ..._selectedSensors.map((s) => ('sensor', s.id, s.name)),
      ..._selectedActuators.map((a) => ('actuator', a.id, a.name)),
    ];

    if (items.isEmpty) {
      return const Text('No sensors or actuators selected');
    }

    return Column(
      children: items.map((item) {
        final currentPin = _pinAssignments[item.$2];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<int>(
            initialValue: currentPin,
            decoration: InputDecoration(
              labelText: item.$3,
              prefixIcon: Icon(
                item.$1 == 'sensor'
                    ? Icons.sensors
                    : Icons.settings_input_component,
              ),
            ),
            items: pins
                .map(
                  (p) =>
                      DropdownMenuItem(value: p.number, child: Text(p.label)),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _pinAssignments[item.$2] = v);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCodeOutput(ThemeData theme) {
    if (_generatedCode == null) return const Text('Generating...');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Wiring Instructions', style: theme.textTheme.titleMedium),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _generatedCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied to clipboard')),
                );
              },
            ),
          ],
        ),
        AppSpacing.verticalSm,
        ..._selectedSensors.map(
          (s) => Card(
            child: ListTile(
              leading: const Icon(Icons.electric_bolt),
              title: Text(s.name),
              subtitle: Text(s.exampleWiring),
            ),
          ),
        ),
        ..._selectedActuators.map(
          (a) => Card(
            child: ListTile(
              leading: const Icon(Icons.electric_bolt),
              title: Text(a.name),
              subtitle: Text(a.exampleWiring),
            ),
          ),
        ),
        AppSpacing.verticalMd,
        Text('Generated Firmware', style: theme.textTheme.titleMedium),
        AppSpacing.verticalSm,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            _generatedCode!,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ),
        AppSpacing.verticalMd,
        Text('Upload Instructions', style: theme.textTheme.titleMedium),
        AppSpacing.verticalSm,
        Card(
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. Install Arduino IDE or PlatformIO\n'
                  '2. Install required libraries (listed in #include)\n'
                  '3. Copy the generated code into a new sketch\n'
                  '4. Update Wi-Fi credentials and MQTT host\n'
                  '5. Select board: ${_selectedBoard?.platformioBoard ?? "esp32dev"}\n'
                  '6. Connect your ${_selectedBoard?.name ?? "board"} via USB\n'
                  '7. Upload the firmware\n'
                  '8. Open Serial Monitor (115200 baud) to verify',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
