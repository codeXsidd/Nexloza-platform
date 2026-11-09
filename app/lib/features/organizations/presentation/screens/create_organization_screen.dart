import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/organization_provider.dart';

class CreateOrganizationScreen extends ConsumerStatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  ConsumerState<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState
    extends ConsumerState<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(organizationsProvider.notifier)
        .createOrganization(
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create organization')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Organization')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Organization Name',
              prefixIcon: const Icon(Icons.business_outlined),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            AppSpacing.verticalMd,
            AppTextField(
              controller: _descController,
              label: 'Description (optional)',
              prefixIcon: const Icon(Icons.description_outlined),
              maxLines: 3,
            ),
            AppSpacing.verticalXl,
            AppButton(
              label: 'Create Organization',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
