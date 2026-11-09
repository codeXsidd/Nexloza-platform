import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/env_config.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../theme/app_spacing.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../domain/entities/device_entity.dart';
import '../providers/device_provider.dart';

class DevicePairingScreen extends ConsumerStatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  ConsumerState<DevicePairingScreen> createState() =>
      _DevicePairingScreenState();
}

class _DevicePairingScreenState extends ConsumerState<DevicePairingScreen> {
  static const _totalSteps = 7;
  static const _pollInterval = Duration(seconds: 5);
  static const _pollTimeout = Duration(seconds: 120);

  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  String? _selectedProjectId;
  HardwarePlatform _selectedPlatform = HardwarePlatform.esp32;

  bool _isProvisioning = false;
  String? _createdDeviceId;
  String? _apiKey;
  String? _apiSecret;

  bool _isPolling = false;
  bool _deviceOnline = false;
  bool _pollTimedOut = false;
  Timer? _pollTimer;
  DateTime? _pollStartedAt;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _typeController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_currentStep == 0 && _selectedProjectId == null) {
      _showSnack('Please select a project');
      return;
    }
    if (_currentStep == 3) {
      if (!_formKey.currentState!.validate()) return;
      _provision();
      return;
    }
    if (_currentStep == 4) {
      _startPolling();
      _goToStep(_currentStep + 1);
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _back() {
    if (_currentStep > 0 && _currentStep < 4) {
      _goToStep(_currentStep - 1);
    }
  }

  Future<void> _provision() async {
    setState(() => _isProvisioning = true);

    final device = await ref
        .read(devicesProvider.notifier)
        .addDevice(
          projectId: _selectedProjectId!,
          name: _nameController.text.trim(),
          deviceType: _typeController.text.trim(),
          hardwarePlatform: _selectedPlatform.name,
        );

    if (!mounted) return;

    if (device == null) {
      setState(() => _isProvisioning = false);
      _showSnack('Failed to create device');
      return;
    }

    final cred = await ref
        .read(devicesProvider.notifier)
        .provisionCredentials(device.id);

    if (!mounted) return;

    if (cred == null) {
      setState(() => _isProvisioning = false);
      _showSnack('Device created but credential provisioning failed');
      return;
    }

    setState(() {
      _isProvisioning = false;
      _createdDeviceId = device.id;
      _apiKey = cred.apiKey;
      _apiSecret = cred.apiSecret;
    });

    _goToStep(4);
  }

  void _startPolling() {
    _pollTimer?.cancel();
    setState(() {
      _isPolling = true;
      _deviceOnline = false;
      _pollTimedOut = false;
      _pollStartedAt = DateTime.now();
    });

    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkDevice());
  }

  Future<void> _checkDevice() async {
    if (_createdDeviceId == null) return;

    ref.invalidate(deviceDetailProvider(_createdDeviceId!));
    final device = await ref.read(
      deviceDetailProvider(_createdDeviceId!).future,
    );

    if (!mounted) return;

    if (device?.isOnline == true) {
      _pollTimer?.cancel();
      setState(() {
        _isPolling = false;
        _deviceOnline = true;
      });
      _goToStep(6);
      return;
    }

    final elapsed = DateTime.now().difference(_pollStartedAt!);
    if (elapsed >= _pollTimeout) {
      _pollTimer?.cancel();
      setState(() {
        _isPolling = false;
        _pollTimedOut = true;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('$label copied');
  }

  String _buildConfigSnippet() {
    return '''config.serverHost      = "${EnvConfig.supabaseUrl}";
config.mqttPort        = ${EnvConfig.mqttPort};
config.deviceId        = "$_createdDeviceId";
config.apiKey          = "$_apiKey";
config.apiSecret       = "$_apiSecret";
config.organizationId  = "YOUR_ORG_ID";
config.projectId       = "$_selectedProjectId";''';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StepSelectProject(
                  selectedProjectId: _selectedProjectId,
                  onChanged: (v) => setState(() => _selectedProjectId = v),
                  ref: ref,
                ),
                _StepSelectHardware(
                  selected: _selectedPlatform,
                  onSelected: (p) => setState(() => _selectedPlatform = p),
                ),
                _StepSetupInstructions(platform: _selectedPlatform),
                _StepDeviceDetails(
                  formKey: _formKey,
                  nameController: _nameController,
                  typeController: _typeController,
                  platform: _selectedPlatform,
                ),
                _StepProvisionResult(
                  deviceId: _createdDeviceId,
                  apiKey: _apiKey,
                  apiSecret: _apiSecret,
                  configSnippet: _createdDeviceId != null
                      ? _buildConfigSnippet()
                      : '',
                  onCopy: _copyToClipboard,
                ),
                _StepVerifyConnection(
                  isPolling: _isPolling,
                  deviceOnline: _deviceOnline,
                  timedOut: _pollTimedOut,
                  onRetry: _startPolling,
                  onSkip: () => _goToStep(6),
                ),
                _StepComplete(
                  deviceId: _createdDeviceId,
                  deviceName: _nameController.text.trim(),
                ),
              ],
            ),
          ),
          _buildBottomBar(theme),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    if (_currentStep == 4 || _currentStep == 5 || _currentStep == 6) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: AppButton(
                  label: 'Back',
                  variant: AppButtonVariant.outlined,
                  onPressed: _back,
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: _currentStep == 3 ? 'Create Device' : 'Next',
                isLoading: _isProvisioning,
                onPressed: _isProvisioning ? null : _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepSelectProject extends StatelessWidget {
  final String? selectedProjectId;
  final ValueChanged<String?> onChanged;
  final WidgetRef ref;

  const _StepSelectProject({
    required this.selectedProjectId,
    required this.onChanged,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsProvider);

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.folder_open, size: 48, color: theme.colorScheme.primary),
          AppSpacing.verticalMd,
          Text('Select a Project', style: theme.textTheme.headlineSmall),
          AppSpacing.verticalSm,
          Text(
            'Choose which project this device belongs to.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalXl,
          projectsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading projects: $e'),
            data: (projects) {
              if (projects.isEmpty) {
                return Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline, size: 32),
                        AppSpacing.verticalSm,
                        const Text(
                          'Create a project first before adding a device.',
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (projects.length == 1 && selectedProjectId == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onChanged(projects.first.id);
                });
              }
              return DropdownButtonFormField<String>(
                initialValue: selectedProjectId,
                decoration: const InputDecoration(
                  labelText: 'Project',
                  prefixIcon: Icon(Icons.folder_outlined),
                  border: OutlineInputBorder(),
                ),
                items: projects
                    .map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    )
                    .toList(),
                onChanged: onChanged,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StepSelectHardware extends StatelessWidget {
  final HardwarePlatform selected;
  final ValueChanged<HardwarePlatform> onSelected;

  const _StepSelectHardware({required this.selected, required this.onSelected});

  static const _platforms = [
    (
      HardwarePlatform.esp32,
      Icons.memory,
      'ESP32',
      'Most popular. WiFi + BLE, dual-core, 18 ADC pins.',
    ),
    (
      HardwarePlatform.esp8266,
      Icons.memory,
      'ESP8266',
      'Budget-friendly. WiFi, 1 ADC pin, smaller footprint.',
    ),
    (
      HardwarePlatform.arduino,
      Icons.developer_board,
      'Arduino',
      'Gateway mode via ESP. Limited direct connectivity.',
    ),
    (
      HardwarePlatform.raspberryPi,
      Icons.developer_board,
      'Raspberry Pi',
      'Full Linux OS. Python client with GPIO support.',
    ),
    (
      HardwarePlatform.genericMqtt,
      Icons.router,
      'Generic MQTT',
      'Any device that speaks MQTT v3.1.1 or v5.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.memory, size: 48, color: theme.colorScheme.primary),
          AppSpacing.verticalMd,
          Text('Select Hardware', style: theme.textTheme.headlineSmall),
          AppSpacing.verticalSm,
          Text(
            'What hardware platform is your device?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalLg,
          ..._platforms.map((p) {
            final isSelected = selected == p.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  side: isSelected
                      ? BorderSide(color: theme.colorScheme.primary, width: 2)
                      : BorderSide.none,
                ),
                color: isSelected
                    ? theme.colorScheme.primaryContainer.withAlpha(60)
                    : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  onTap: () => onSelected(p.$1),
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            p.$2,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.horizontalMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.$3, style: theme.textTheme.titleMedium),
                              Text(
                                p.$4,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StepSetupInstructions extends StatelessWidget {
  final HardwarePlatform platform;

  const _StepSetupInstructions({required this.platform});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, instructions, docRef) = _getInstructions();

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.build_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          AppSpacing.verticalMd,
          Text('Setup Instructions', style: theme.textTheme.headlineSmall),
          AppSpacing.verticalSm,
          Text(
            'Prepare your $title before continuing.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalLg,
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.checklist, color: theme.colorScheme.primary),
                      AppSpacing.horizontalSm,
                      Text('Requirements', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  AppSpacing.verticalMd,
                  ...instructions.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(line)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.verticalMd,
          Card(
            color: theme.colorScheme.secondaryContainer.withAlpha(60),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.secondary),
                  AppSpacing.horizontalSm,
                  Expanded(
                    child: Text(
                      'See $docRef for detailed wiring diagrams and library installation.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, List<String>, String) _getInstructions() => switch (platform) {
    HardwarePlatform.esp32 => (
      'ESP32',
      [
        'Install PlatformIO IDE or Arduino IDE on your computer.',
        'Add the NexlozaClient SDK library to your project.',
        'Connect your ESP32 via USB cable.',
        'Ensure your ESP32 is in upload mode (hold BOOT if needed).',
        'Have your WiFi network name and password ready.',
      ],
      'docs/ESP32_SETUP.md',
    ),
    HardwarePlatform.esp8266 => (
      'ESP8266',
      [
        'Install PlatformIO IDE or Arduino IDE on your computer.',
        'Add the NexlozaClient SDK library to your project.',
        'Connect your ESP8266/NodeMCU via USB cable.',
        'Only 1 analog pin (A0) is available on ESP8266.',
        'Have your WiFi network name and password ready.',
      ],
      'docs/ESP8266_SETUP.md',
    ),
    HardwarePlatform.arduino => (
      'Arduino',
      [
        'Arduino boards require an ESP32 or ESP8266 as a WiFi gateway.',
        'Connect the Arduino to the gateway via Serial.',
        'Install Arduino IDE with the appropriate board package.',
        'The gateway forwards Serial data to MQTT.',
      ],
      'docs/ARDUINO_IDE_SETUP.md',
    ),
    HardwarePlatform.raspberryPi => (
      'Raspberry Pi',
      [
        'Install Python 3.7+ on your Raspberry Pi.',
        'Install paho-mqtt: pip3 install paho-mqtt',
        'Copy nexloza_device.py to your Pi.',
        'Configure environment variables for credentials.',
      ],
      'docs/ESP32_SETUP.md (Raspberry Pi section)',
    ),
    HardwarePlatform.genericMqtt || HardwarePlatform.other => (
      'MQTT Device',
      [
        'Any MQTT client supporting v3.1.1 or v5 can connect.',
        'Use the Nexloza v1 topic format: nexloza/v1/{org}/{project}/{device}/{channel}',
        'Authenticate using the device-auth Edge Function.',
        'Publish telemetry as JSON to the telemetry channel.',
      ],
      'firmware/README.md',
    ),
  };
}

class _StepDeviceDetails extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController typeController;
  final HardwarePlatform platform;

  const _StepDeviceDetails({
    required this.formKey,
    required this.nameController,
    required this.typeController,
    required this.platform,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.edit_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            AppSpacing.verticalMd,
            Text('Device Details', style: theme.textTheme.headlineSmall),
            AppSpacing.verticalSm,
            Text(
              'Give your device a name and type.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.verticalXl,
            AppTextField(
              controller: nameController,
              label: 'Device Name',
              hint: 'e.g., Living Room Sensor',
              prefixIcon: const Icon(Icons.label_outlined),
              validator: (v) => Validators.required(v, 'Device name'),
            ),
            AppSpacing.verticalMd,
            AppTextField(
              controller: typeController,
              label: 'Device Type',
              hint: 'e.g., relay, sensor, switch, multi-sensor',
              prefixIcon: const Icon(Icons.category_outlined),
              validator: (v) => Validators.required(v, 'Device type'),
            ),
            AppSpacing.verticalMd,
            Card(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Row(
                  children: [
                    Icon(
                      _platformIcon(platform),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    AppSpacing.horizontalSm,
                    Text(
                      'Platform: ${platform.displayName}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _platformIcon(HardwarePlatform p) => switch (p) {
    HardwarePlatform.esp32 || HardwarePlatform.esp8266 => Icons.memory,
    HardwarePlatform.raspberryPi ||
    HardwarePlatform.arduino => Icons.developer_board,
    _ => Icons.router,
  };
}

class _StepProvisionResult extends StatelessWidget {
  final String? deviceId;
  final String? apiKey;
  final String? apiSecret;
  final String configSnippet;
  final void Function(String text, String label) onCopy;

  const _StepProvisionResult({
    required this.deviceId,
    required this.apiKey,
    required this.apiSecret,
    required this.configSnippet,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (deviceId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.key, size: 48, color: theme.colorScheme.primary),
          AppSpacing.verticalMd,
          Text('Device Credentials', style: theme.textTheme.headlineSmall),
          AppSpacing.verticalSm,
          Text(
            'Save these credentials now. The secret will not be shown again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.verticalLg,
          _CredentialTile(
            label: 'Device ID',
            value: deviceId!,
            onCopy: () => onCopy(deviceId!, 'Device ID'),
          ),
          _CredentialTile(
            label: 'API Key',
            value: apiKey ?? '',
            onCopy: () => onCopy(apiKey ?? '', 'API Key'),
          ),
          _CredentialTile(
            label: 'API Secret',
            value: apiSecret ?? '',
            onCopy: () => onCopy(apiSecret ?? '', 'API Secret'),
          ),
          AppSpacing.verticalLg,
          Text('Firmware Configuration', style: theme.textTheme.titleMedium),
          AppSpacing.verticalSm,
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Stack(
              children: [
                Padding(
                  padding: AppSpacing.cardPadding,
                  child: SelectableText(
                    configSnippet,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy configuration',
                    onPressed: () => onCopy(configSnippet, 'Configuration'),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalLg,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onCopy(
                'DEVICE_ID=$deviceId\nAPI_KEY=$apiKey\nAPI_SECRET=$apiSecret',
                'All credentials',
              ),
              icon: const Icon(Icons.copy_all),
              label: const Text('Copy All Credentials'),
            ),
          ),
          AppSpacing.verticalMd,
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () {
                final parent = context
                    .findAncestorStateOfType<_DevicePairingScreenState>();
                parent?._next();
              },
              icon: const Icon(Icons.wifi_find),
              label: const Text('Verify Connection'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _CredentialTile({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: ListTile(
          title: Text(label, style: theme.textTheme.labelMedium),
          subtitle: SelectableText(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: onCopy,
          ),
        ),
      ),
    );
  }
}

class _StepVerifyConnection extends StatelessWidget {
  final bool isPolling;
  final bool deviceOnline;
  final bool timedOut;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  const _StepVerifyConnection({
    required this.isPolling,
    required this.deviceOnline,
    required this.timedOut,
    required this.onRetry,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isPolling) ...[
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                color: theme.colorScheme.primary,
              ),
            ),
            AppSpacing.verticalXl,
            Text(
              'Waiting for device to connect...',
              style: theme.textTheme.titleMedium,
            ),
            AppSpacing.verticalSm,
            Text(
              'Upload your firmware and power on the device.\nThis will check every 5 seconds.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (timedOut) ...[
            Icon(
              Icons.timer_off,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.verticalXl,
            Text('Connection timed out', style: theme.textTheme.titleMedium),
            AppSpacing.verticalSm,
            Text(
              'The device did not come online within 2 minutes.\n'
              'You can retry or skip and check later.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.verticalXl,
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            AppSpacing.verticalSm,
            OutlinedButton(
              onPressed: onSkip,
              child: const Text('Skip — connect later'),
            ),
          ] else ...[
            Icon(Icons.check_circle, size: 80, color: const Color(0xFF4CAF50)),
            AppSpacing.verticalXl,
            Text('Device Connected!', style: theme.textTheme.titleMedium),
          ],
        ],
      ),
    );
  }
}

class _StepComplete extends StatelessWidget {
  final String? deviceId;
  final String deviceName;

  const _StepComplete({required this.deviceId, required this.deviceName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          AppSpacing.verticalXl,
          Icon(Icons.celebration, size: 64, color: theme.colorScheme.primary),
          AppSpacing.verticalLg,
          Text('Device Ready!', style: theme.textTheme.headlineSmall),
          AppSpacing.verticalSm,
          Text(
            '"$deviceName" has been added to your project.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalXl,
          Text(
            'What would you like to do next?',
            style: theme.textTheme.titleSmall,
          ),
          AppSpacing.verticalLg,
          _ActionCard(
            icon: Icons.sensors,
            title: 'Configure Sensors',
            subtitle: 'Register temperature, humidity, motion sensors and more',
            onTap: () {
              if (deviceId != null) {
                context.push('/devices/$deviceId/sensors');
              }
            },
          ),
          AppSpacing.verticalSm,
          _ActionCard(
            icon: Icons.settings_input_component,
            title: 'Configure Actuators',
            subtitle: 'Set up relays, fans, lights and other outputs',
            onTap: () {
              if (deviceId != null) {
                context.push('/devices/$deviceId/actuators');
              }
            },
          ),
          AppSpacing.verticalSm,
          _ActionCard(
            icon: Icons.dashboard_outlined,
            title: 'View Device',
            subtitle: 'See device details, telemetry and commands',
            onTap: () {
              if (deviceId != null) {
                context.go('/devices/$deviceId');
              }
            },
          ),
          AppSpacing.verticalLg,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
