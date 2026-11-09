import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../domain/entities/trigger_entity.dart';
import '../../domain/entities/action_entity.dart';
import '../providers/automation_provider.dart';

class CreateAutomationScreen extends ConsumerStatefulWidget {
  const CreateAutomationScreen({super.key});

  @override
  ConsumerState<CreateAutomationScreen> createState() =>
      _CreateAutomationScreenState();
}

class _CreateAutomationScreenState
    extends ConsumerState<CreateAutomationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedProjectId;
  TriggerType _selectedTrigger = TriggerType.sensorThreshold;
  ActionType _selectedAction = ActionType.deviceCommand;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project')));
      return;
    }

    setState(() => _isSubmitting = true);

    final description = _descriptionController.text.trim().isNotEmpty
        ? '${_selectedTrigger.displayName} → ${_selectedAction.displayName}. ${_descriptionController.text.trim()}'
        : '${_selectedTrigger.displayName} → ${_selectedAction.displayName}';

    final success = await ref
        .read(automationsProvider.notifier)
        .createAutomation(
          projectId: _selectedProjectId!,
          name: _nameController.text.trim(),
          description: description,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Automation created')));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create automation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Automation')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            Text('Project', style: theme.textTheme.titleMedium),
            AppSpacing.verticalSm,
            projectsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Failed to load projects'),
              data: (projects) {
                if (projects.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: Text(
                        'No projects found. Create a project first.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedProjectId,
                  decoration: const InputDecoration(
                    labelText: 'Select Project',
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                  items: projects
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                  validator: (v) =>
                      v == null ? 'Please select a project' : null,
                  onChanged: (v) => setState(() => _selectedProjectId = v),
                );
              },
            ),
            AppSpacing.verticalLg,
            AppTextField(
              controller: _nameController,
              label: 'Automation Name',
              prefixIcon: const Icon(Icons.auto_awesome_outlined),
              validator: (v) => Validators.required(v, 'Name'),
            ),
            AppSpacing.verticalMd,
            AppTextField(
              controller: _descriptionController,
              label: 'Description (optional)',
              prefixIcon: const Icon(Icons.description_outlined),
              maxLines: 2,
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
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(
                        () =>
                            _selectedTrigger = v ?? TriggerType.sensorThreshold,
                      ),
                    ),
                    AppSpacing.verticalMd,
                    _buildTriggerConfig(theme),
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
                          .map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: Text(a.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(
                        () => _selectedAction = v ?? ActionType.deviceCommand,
                      ),
                    ),
                    AppSpacing.verticalMd,
                    _buildActionConfig(theme),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalXl,
            AppButton(
              label: 'Create Automation',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
            AppSpacing.verticalSm,
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.outlined,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerConfig(ThemeData theme) {
    final hint = switch (_selectedTrigger) {
      TriggerType.sensorThreshold =>
        'Fires when a sensor reading crosses a threshold value.',
      TriggerType.deviceStateChange =>
        'Fires when a device changes state (online/offline).',
      TriggerType.schedule => 'Fires on a recurring schedule (cron).',
      TriggerType.time => 'Fires at a specific time of day.',
      TriggerType.webhook => 'Fires when an external webhook is received.',
      TriggerType.manual => 'Fires only when manually triggered.',
      TriggerType.deviceOnline => 'Fires when a device comes online.',
      TriggerType.deviceOffline => 'Fires when a device goes offline.',
    };
    return Text(
      hint,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildActionConfig(ThemeData theme) {
    final hint = switch (_selectedAction) {
      ActionType.deviceCommand => 'Sends a command to a target device.',
      ActionType.notification => 'Sends a push notification.',
      ActionType.email => 'Sends an email alert.',
      ActionType.webhook => 'Calls an external webhook URL.',
      ActionType.runScene => 'Activates a predefined scene.',
      ActionType.runAutomation => 'Triggers another automation.',
      ActionType.aiRecommendation => 'Requests an AI-powered recommendation.',
    };
    return Text(
      hint,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
