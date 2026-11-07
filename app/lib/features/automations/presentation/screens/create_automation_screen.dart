import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/trigger_entity.dart';
import '../../domain/entities/action_entity.dart';

class CreateAutomationScreen extends ConsumerStatefulWidget {
  const CreateAutomationScreen({super.key});

  @override
  ConsumerState<CreateAutomationScreen> createState() => _CreateAutomationScreenState();
}

class _CreateAutomationScreenState extends ConsumerState<CreateAutomationScreen> {
  final _nameController = TextEditingController();
  TriggerType _selectedTrigger = TriggerType.sensorThreshold;
  ActionType _selectedAction = ActionType.deviceCommand;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Automation')),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          AppTextField(
            controller: _nameController,
            label: 'Automation Name',
            prefixIcon: const Icon(Icons.auto_awesome_outlined),
            validator: (v) => Validators.required(v, 'Name'),
          ),
          AppSpacing.verticalLg,
          Text('When this happens...', style: theme.textTheme.titleMedium),
          AppSpacing.verticalSm,
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                children: [
                  DropdownButtonFormField<TriggerType>(
                    initialValue: _selectedTrigger,
                    decoration: const InputDecoration(
                      labelText: 'Trigger Type',
                      prefixIcon: Icon(Icons.bolt),
                    ),
                    items: TriggerType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedTrigger = v ?? TriggerType.sensorThreshold),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.verticalLg,
          Text('Do this...', style: theme.textTheme.titleMedium),
          AppSpacing.verticalSm,
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                children: [
                  DropdownButtonFormField<ActionType>(
                    initialValue: _selectedAction,
                    decoration: const InputDecoration(
                      labelText: 'Action Type',
                      prefixIcon: Icon(Icons.play_arrow),
                    ),
                    items: ActionType.values
                        .map((a) => DropdownMenuItem(value: a, child: Text(a.displayName)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAction = v ?? ActionType.deviceCommand),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.verticalXl,
          AppButton(
            label: 'Create Automation',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Automation creation requires Supabase connection')),
              );
            },
          ),
          AppSpacing.verticalSm,
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outlined,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
