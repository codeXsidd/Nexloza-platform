import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../domain/entities/scene_entity.dart';
import '../providers/scene_provider.dart';

class CreateSceneScreen extends ConsumerStatefulWidget {
  const CreateSceneScreen({super.key});

  @override
  ConsumerState<CreateSceneScreen> createState() => _CreateSceneScreenState();
}

class _CreateSceneScreenState extends ConsumerState<CreateSceneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedProjectId;
  String? _selectedPreset;
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

    final success = await ref
        .read(scenesProvider.notifier)
        .createScene(
          projectId: _selectedProjectId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          icon: _selectedPreset?.toLowerCase(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Scene created')));
      context.pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create scene')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Scene')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            projectsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Failed to load projects'),
              data: (projects) {
                if (projects.isEmpty) {
                  return const Text('No projects. Create a project first.');
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedProjectId,
                  decoration: const InputDecoration(
                    labelText: 'Project',
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
            Text('Preset (optional)', style: theme.textTheme.titleMedium),
            AppSpacing.verticalSm,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Scene.presets.map((preset) {
                final selected = _selectedPreset == preset;
                return FilterChip(
                  selected: selected,
                  label: Text(preset),
                  onSelected: (v) {
                    setState(() {
                      _selectedPreset = v ? preset : null;
                      if (v && _nameController.text.isEmpty) {
                        _nameController.text = preset;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            AppSpacing.verticalLg,
            AppTextField(
              controller: _nameController,
              label: 'Scene Name',
              prefixIcon: const Icon(Icons.theater_comedy_outlined),
              validator: (v) => Validators.required(v, 'Name'),
            ),
            AppSpacing.verticalMd,
            AppTextField(
              controller: _descriptionController,
              label: 'Description (optional)',
              prefixIcon: const Icon(Icons.description_outlined),
              maxLines: 2,
            ),
            AppSpacing.verticalXl,
            AppButton(
              label: 'Create Scene',
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
}
