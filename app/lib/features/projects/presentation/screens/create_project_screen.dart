import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/project_entity.dart';
import '../providers/project_provider.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Custom';
  bool _isLoading = false;
  bool _showForm = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _selectTemplate(ProjectTemplate template) {
    _nameController.text = template.name == 'Custom Project'
        ? ''
        : template.name;
    _descriptionController.text = template.description;
    _selectedCategory = template.category;
    setState(() => _showForm = true);
  }

  Future<void> _onCreate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await ref
        .read(projectsProvider.notifier)
        .createProject(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _selectedCategory.toLowerCase().replaceAll(' ', '_'),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Project created')));
      context.pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create project')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_showForm ? 'New Project' : 'Choose Template'),
        leading: _showForm
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showForm = false),
              )
            : null,
      ),
      body: _showForm ? _buildForm(theme) : _buildTemplateGrid(theme),
    );
  }

  Widget _buildTemplateGrid(ThemeData theme) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Text('What are you building?', style: theme.textTheme.headlineSmall),
        AppSpacing.verticalSm,
        Text(
          'Choose a template to get started or create a custom project.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.verticalLg,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: ProjectTemplate.templates.length,
          itemBuilder: (context, index) {
            final t = ProjectTemplate.templates[index];
            return _TemplateCard(template: t, onTap: () => _selectTemplate(t));
          },
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme) {
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
            AppSpacing.verticalXl,
            AppButton(
              label: 'Create Project',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _onCreate,
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

class _TemplateCard extends StatelessWidget {
  final ProjectTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(template.icon, size: 36, color: theme.colorScheme.primary),
              AppSpacing.verticalSm,
              Text(
                template.name,
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.verticalXs,
              Text(
                template.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
