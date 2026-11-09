import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../providers/dashboard_provider.dart';

class CreateDashboardScreen extends ConsumerStatefulWidget {
  const CreateDashboardScreen({super.key});

  @override
  ConsumerState<CreateDashboardScreen> createState() =>
      _CreateDashboardScreenState();
}

class _CreateDashboardScreenState extends ConsumerState<CreateDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedProjectId;
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

    final dashboard = await ref
        .read(dashboardsProvider.notifier)
        .createDashboard(
          projectId: _selectedProjectId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (dashboard != null) {
      context.pushReplacementNamed(
        RouteNames.dashboardEditor,
        pathParameters: {'id': dashboard.id},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create dashboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Dashboard')),
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
            AppTextField(
              controller: _nameController,
              label: 'Dashboard Name',
              prefixIcon: const Icon(Icons.dashboard_outlined),
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
              label: 'Create Dashboard',
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
