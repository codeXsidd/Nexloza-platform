import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/device_entity.dart';
import '../providers/device_provider.dart';

class EditDeviceScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const EditDeviceScreen({super.key, required this.deviceId});

  @override
  ConsumerState<EditDeviceScreen> createState() => _EditDeviceScreenState();
}

class _EditDeviceScreenState extends ConsumerState<EditDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _firmwareController = TextEditingController();
  final _macController = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _firmwareController.dispose();
    _macController.dispose();
    super.dispose();
  }

  void _initFromDevice(Device device) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = device.name;
    _firmwareController.text = device.firmwareVersion ?? '';
    _macController.text = device.macAddress ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updates = <String, dynamic>{'name': _nameController.text.trim()};
    final fw = _firmwareController.text.trim();
    if (fw.isNotEmpty) updates['firmware_version'] = fw;
    final mac = _macController.text.trim();
    if (mac.isNotEmpty) updates['mac_address'] = mac;

    final success = await ref
        .read(devicesProvider.notifier)
        .updateDevice(widget.deviceId, updates);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ref.invalidate(deviceDetailProvider(widget.deviceId));
      context.pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update device')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceAsync = ref.watch(deviceDetailProvider(widget.deviceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Device')),
      body: deviceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (device) {
          if (device == null) {
            return const Center(child: Text('Device not found'));
          }
          _initFromDevice(device);
          return SingleChildScrollView(
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
                            'Device Info',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          AppSpacing.verticalMd,
                          AppTextField(
                            controller: _nameController,
                            label: 'Device Name',
                            prefixIcon: const Icon(Icons.label_outlined),
                            validator: (v) =>
                                Validators.required(v, 'Device name'),
                          ),
                          AppSpacing.verticalMd,
                          AppTextField(
                            controller: _firmwareController,
                            label: 'Firmware Version',
                            prefixIcon: const Icon(
                              Icons.system_update_outlined,
                            ),
                          ),
                          AppSpacing.verticalMd,
                          AppTextField(
                            controller: _macController,
                            label: 'MAC Address',
                            prefixIcon: const Icon(Icons.router_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.verticalMd,
                  Card(
                    child: Padding(
                      padding: AppSpacing.cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Device Details',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          AppSpacing.verticalSm,
                          _ReadOnlyRow(
                            'Platform',
                            device.hardwarePlatform.displayName,
                          ),
                          _ReadOnlyRow('Type', device.deviceType),
                          _ReadOnlyRow('ID', device.id),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.verticalXl,
                  AppButton(
                    label: 'Save Changes',
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
          );
        },
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
