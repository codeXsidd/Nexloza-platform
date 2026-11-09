import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../theme/app_spacing.dart';
import '../../data/actuator_repository.dart';
import '../../domain/entities/actuator_entity.dart';
import '../providers/actuator_provider.dart';
import '../providers/device_provider.dart';

class ManageActuatorsScreen extends ConsumerWidget {
  final String deviceId;

  const ManageActuatorsScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actuatorsAsync = ref.watch(deviceActuatorsProvider(deviceId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Actuators'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(deviceActuatorsProvider(deviceId)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddActuatorDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: actuatorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (actuators) {
          if (actuators.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.settings_input_component_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.verticalMd,
                  Text(
                    'No actuators registered',
                    style: theme.textTheme.bodyLarge,
                  ),
                  AppSpacing.verticalSm,
                  Text(
                    'Tap + to add an actuator definition',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: actuators.length,
            itemBuilder: (context, index) =>
                _ActuatorTile(actuator: actuators[index], deviceId: deviceId),
          );
        },
      ),
    );
  }

  void _showAddActuatorDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final keyCtrl = TextEditingController();
    ActuatorType selectedType = ActuatorType.relay;
    ControlType selectedControl = ControlType.toggle;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Actuator'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(controller: nameCtrl, label: 'Actuator Name'),
                AppSpacing.verticalSm,
                AppTextField(
                  controller: keyCtrl,
                  label: 'Command Key (e.g., relay_1)',
                ),
                AppSpacing.verticalSm,
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
                AppSpacing.verticalSm,
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
                if (nameCtrl.text.trim().isEmpty ||
                    keyCtrl.text.trim().isEmpty) {
                  return;
                }
                final device = await ref.read(
                  deviceDetailProvider(deviceId).future,
                );
                if (device == null) return;
                final repo = ref.read(actuatorRepositoryProvider);
                await repo.createActuator(
                  deviceId: deviceId,
                  projectId: device.projectId,
                  name: nameCtrl.text.trim(),
                  actuatorType: selectedType.dbValue,
                  controlType: selectedControl.dbValue,
                  commandKey: keyCtrl.text.trim(),
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
}

class _ActuatorTile extends ConsumerWidget {
  final ActuatorDefinition actuator;
  final String deviceId;

  const _ActuatorTile({required this.actuator, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
          '${actuator.actuatorType.displayName} • ${actuator.controlType.displayName}'
          ' • Key: ${actuator.commandKey}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final confirmed = await showConfirmationDialog(
              context,
              title: 'Delete Actuator',
              message: 'Remove "${actuator.name}" from this device?',
              isDestructive: true,
            );
            if (confirmed) {
              final repo = ref.read(actuatorRepositoryProvider);
              await repo.deleteActuator(actuator.id);
              ref.invalidate(deviceActuatorsProvider(deviceId));
            }
          },
        ),
      ),
    );
  }
}
