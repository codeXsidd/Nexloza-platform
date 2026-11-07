import 'package:flutter/material.dart';
import '../../../../theme/app_spacing.dart';

class DevicePairingScreen extends StatelessWidget {
  const DevicePairingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pair Device')),
      body: Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_scanner, size: 120, color: theme.colorScheme.primary),
              AppSpacing.verticalLg,
              Text('Scan QR Code', style: theme.textTheme.headlineSmall),
              AppSpacing.verticalSm,
              Text(
                'Point your camera at the QR code displayed on your device to pair it.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              AppSpacing.verticalXl,
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt),
                label: const Text('Open Camera'),
              ),
              AppSpacing.verticalMd,
              OutlinedButton(
                onPressed: () {},
                child: const Text('Enter Code Manually'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
