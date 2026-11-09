import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../domain/entities/device_entity.dart';
import '../providers/device_provider.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  HardwarePlatform _platform = HardwarePlatform.esp32;
  String? _selectedProjectId;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
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

    setState(() => _isLoading = true);

    final device = await ref
        .read(devicesProvider.notifier)
        .addDevice(
          projectId: _selectedProjectId!,
          name: _nameController.text.trim(),
          deviceType: _typeController.text.trim(),
          hardwarePlatform: _platform.name,
        );

    if (!mounted) return;

    if (device != null) {
      final cred = await ref
          .read(devicesProvider.notifier)
          .provisionCredentials(device.id);

      if (!mounted) return;

      if (cred != null) {
        await _showCredentialsDialog(cred.apiKey, cred.apiSecret);
      }

      if (mounted) context.pop();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to add device')));
    }
  }

  Future<void> _showCredentialsDialog(String apiKey, String apiSecret) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Device Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save these credentials now. The secret will not be shown again.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('API Key:'),
            SelectableText(
              apiKey,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            const Text('API Secret:'),
            SelectableText(
              apiSecret,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: 'API_KEY=$apiKey\nAPI_SECRET=$apiSecret'),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Credentials copied')),
              );
            },
            child: const Text('Copy All'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Device')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Setup',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      AppSpacing.verticalMd,
                      projectsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error loading projects: $e'),
                        data: (projects) {
                          if (projects.isEmpty) {
                            return const Text(
                              'Create a project first before adding devices.',
                            );
                          }
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedProjectId,
                            decoration: const InputDecoration(
                              labelText: 'Project',
                              prefixIcon: Icon(Icons.folder_outlined),
                            ),
                            items: projects
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(p.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedProjectId = v),
                            validator: (v) =>
                                v == null ? 'Select a project' : null,
                          );
                        },
                      ),
                      AppSpacing.verticalMd,
                      AppTextField(
                        controller: _nameController,
                        label: 'Device Name',
                        prefixIcon: const Icon(Icons.label_outlined),
                        validator: (v) => Validators.required(v, 'Device name'),
                      ),
                      AppSpacing.verticalMd,
                      AppTextField(
                        controller: _typeController,
                        label: 'Device Type (e.g., relay, sensor, switch)',
                        prefixIcon: const Icon(Icons.category_outlined),
                        validator: (v) => Validators.required(v, 'Device type'),
                      ),
                      AppSpacing.verticalMd,
                      DropdownButtonFormField<HardwarePlatform>(
                        initialValue: _platform,
                        decoration: const InputDecoration(
                          labelText: 'Hardware Platform',
                          prefixIcon: Icon(Icons.memory),
                        ),
                        items: HardwarePlatform.values
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(
                          () => _platform = v ?? HardwarePlatform.esp32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.verticalXl,
              AppButton(
                label: 'Add Device',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
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
      ),
    );
  }
}
