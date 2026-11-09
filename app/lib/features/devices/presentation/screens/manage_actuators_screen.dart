import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/actuator_repository.dart';
import '../../domain/entities/actuator_entity.dart';
import '../providers/actuator_provider.dart';

class ManageActuatorsScreen extends ConsumerWidget {
  final String deviceId;

  const ManageActuatorsScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actuatorsAsync = ref.watch(deviceActuatorsProvider(deviceId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Actuators')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Actuator'),
      ),
      body: actuatorsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(deviceActuatorsProvider(deviceId)),
        ),
        data: (actuators) {
          if (actuators.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.settings_input_component_outlined,
              title: 'No Actuators',
              subtitle: 'Add actuators to control your device',
              actionLabel: 'Add Actuator',
              onAction: () => _showAddDialog(context, ref),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: actuators.length,
            itemBuilder: (context, index) {
              final actuator = actuators[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.settings_input_component,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  title: Text(actuator.name),
                  subtitle: Text(
                    '${actuator.actuatorType.displayName} · ${actuator.controlType.displayName}'
                    ' · ${actuator.commandKey}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () =>
                            _showEditDialog(context, ref, actuator),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () => _confirmDelete(context, ref, actuator),
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
    final cmdKeyCtl = TextEditingController();
    var selectedType = ActuatorType.relay;
    var selectedControl = ControlType.toggle;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Actuator'),
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
                  controller: cmdKeyCtl,
                  decoration: const InputDecoration(
                    labelText: 'Command Key',
                    hintText: 'e.g. relay_1',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ActuatorType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Actuator Type'),
                  items: ActuatorType.values
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
                DropdownButtonFormField<ControlType>(
                  initialValue: selectedControl,
                  decoration: const InputDecoration(labelText: 'Control Type'),
                  items: ControlType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(
                    () => selectedControl = v ?? selectedControl,
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
                if (nameCtl.text.trim().isEmpty ||
                    cmdKeyCtl.text.trim().isEmpty) {
                  return;
                }
                await ref
                    .read(actuatorRepositoryProvider)
                    .createActuator(
                      deviceId: deviceId,
                      projectId: '',
                      name: nameCtl.text.trim(),
                      actuatorType: selectedType.dbValue,
                      controlType: selectedControl.dbValue,
                      commandKey: cmdKeyCtl.text.trim(),
                    );
                ref.invalidate(deviceActuatorsProvider(deviceId));
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
    ActuatorDefinition actuator,
  ) {
    final nameCtl = TextEditingController(text: actuator.name);
    final telKeyCtl = TextEditingController(text: actuator.telemetryKey ?? '');
    final minCtl = TextEditingController(text: actuator.minValue.toString());
    final maxCtl = TextEditingController(text: actuator.maxValue.toString());
    final stepCtl = TextEditingController(text: actuator.step.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${actuator.name}'),
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
                  labelText: 'Command Key',
                  hintText: actuator.commandKey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: telKeyCtl,
                decoration: const InputDecoration(
                  labelText: 'Telemetry Key (optional)',
                ),
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
              const SizedBox(height: 8),
              TextField(
                controller: stepCtl,
                decoration: const InputDecoration(labelText: 'Step'),
                keyboardType: TextInputType.number,
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
              if (telKeyCtl.text.trim().isNotEmpty) {
                updates['telemetry_key'] = telKeyCtl.text.trim();
              }
              final min = double.tryParse(minCtl.text);
              if (min != null) updates['min_value'] = min;
              final max = double.tryParse(maxCtl.text);
              if (max != null) updates['max_value'] = max;
              final step = double.tryParse(stepCtl.text);
              if (step != null) updates['step'] = step;
              if (updates.isNotEmpty) {
                await ref
                    .read(actuatorRepositoryProvider)
                    .updateActuator(actuator.id, updates);
                ref.invalidate(deviceActuatorsProvider(deviceId));
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
    ActuatorDefinition actuator,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Actuator',
      message: 'Remove "${actuator.name}" from this device?',
      isDestructive: true,
    );
    if (confirmed) {
      await ref.read(actuatorRepositoryProvider).deleteActuator(actuator.id);
      ref.invalidate(deviceActuatorsProvider(deviceId));
    }
  }
}
