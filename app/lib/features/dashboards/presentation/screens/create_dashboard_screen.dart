import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../domain/entities/dashboard_entity.dart';
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
  DashboardTemplate? _selectedTemplate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _selectTemplate(DashboardTemplate template) {
    setState(() {
      _selectedTemplate = template;
      if (_nameController.text.isEmpty ||
          Dashboard.templates.any((t) => t.name == _nameController.text)) {
        _nameController.text = template.name;
      }
      if (_descriptionController.text.isEmpty ||
          Dashboard.templates.any(
            (t) => t.description == _descriptionController.text,
          )) {
        _descriptionController.text = template.description;
      }
    });
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
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Dashboard')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            Text('Choose a Template', style: theme.textTheme.titleMedium),
            AppSpacing.verticalSm,
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: Dashboard.templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final template = Dashboard.templates[index];
                  final selected = _selectedTemplate == template;
                  return _TemplateCard(
                    template: template,
                    selected: selected,
                    onTap: () => _selectTemplate(template),
                  );
                },
              ),
            ),
            AppSpacing.verticalLg,
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

IconData _templateIcon(String iconName) {
  return switch (iconName) {
    'home' => Icons.home,
    'grass' => Icons.grass,
    'water_drop' => Icons.water_drop,
    'cloud' => Icons.cloud,
    'waves' => Icons.waves,
    'bolt' => Icons.bolt,
    'factory' => Icons.factory,
    'precision_manufacturing' => Icons.precision_manufacturing,
    'shield' => Icons.shield,
    'dashboard_customize' => Icons.dashboard_customize,
    _ => Icons.dashboard,
  };
}

class _TemplateCard extends StatelessWidget {
  final DashboardTemplate template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 130,
      child: Card(
        elevation: selected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: selected
              ? BorderSide(color: theme.colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _templateIcon(template.icon),
                  size: 28,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  template.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
