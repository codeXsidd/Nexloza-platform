import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/device_entity.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              AppSpacing.verticalLg,
              Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Pairing',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      AppSpacing.verticalSm,
                      Text(
                        'Scan a QR code on your device to automatically configure it.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      AppSpacing.verticalMd,
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan QR Code'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.verticalXl,
              AppButton(
                label: 'Add Device',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Device registration requires Supabase connection',
                        ),
                      ),
                    );
                  }
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
        ),
      ),
    );
  }
}
