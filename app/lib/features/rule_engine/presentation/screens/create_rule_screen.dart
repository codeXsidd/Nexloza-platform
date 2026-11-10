import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_spacing.dart';
import '../../data/rule_repository.dart';
import '../providers/rule_provider.dart';

class CreateRuleScreen extends ConsumerStatefulWidget {
  final String projectId;

  const CreateRuleScreen({super.key, required this.projectId});

  @override
  ConsumerState<CreateRuleScreen> createState() => _CreateRuleScreenState();
}

class _CreateRuleScreenState extends ConsumerState<CreateRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(ruleRepositoryProvider);
      final result = await repo.createRule(
        projectId: widget.projectId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (!mounted) return;

      result.when(
        success: (_) {
          ref.invalidate(rulesProvider(widget.projectId));
          context.pop();
        },
        failure: (f) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(f.message)));
        },
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Rule'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Rule Name',
                hintText: 'Enter a name for this rule',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a rule name';
                }
                return null;
              },
            ),
            AppSpacing.verticalSm,
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional description',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
