import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/project_entity.dart';
import '../providers/project_provider.dart';

class EditProjectScreen extends ConsumerStatefulWidget {
  final String projectId;

  const EditProjectScreen({super.key, required this.projectId});

  @override
  ConsumerState<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends ConsumerState<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Custom';
  bool _isActive = true;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initFromProject(Project project) {
    if (_initialized) return;
    _nameController.text = project.name;
    _descriptionController.text = project.description ?? '';
    _selectedCategory = project.category ?? 'Custom';
    _isActive = project.isActive;
    _initialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(projectsProvider.notifier)
        .updateProject(widget.projectId, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'category': _selectedCategory.toLowerCase().replaceAll(' ', '_'),
          'is_active': _isActive,
        });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ref.invalidate(projectDetailProvider(widget.projectId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project edit saved or queued')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update project')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectDetailProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Project')),
      body: projectAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(projectDetailProvider(widget.projectId)),
        ),
        data: (project) {
          if (project == null) {
            return const AppErrorWidget(message: 'Project not found');
          }
          _initFromProject(project);
          return SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _nameController,
                    label: 'Project Name',
                    prefixIcon: const Icon(Icons.folder_outlined),
                    validator: (v) => Validators.required(v, 'Project name'),
                  ),
                  AppSpacing.verticalMd,
                  AppTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    maxLines: 3,
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                  AppSpacing.verticalMd,
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: Project.categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCategory = v ?? 'Custom'),
                  ),
                  AppSpacing.verticalMd,
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: const Text('Inactive projects are paused'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  AppSpacing.verticalXl,
                  AppButton(
                    label: 'Save Changes',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _save,
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
        },
      ),
    );
  }
}
