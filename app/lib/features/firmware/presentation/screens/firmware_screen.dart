import 'package:flutter/material.dart';

import '../../../../shared/widgets/empty_state_widget.dart';

class FirmwareScreen extends StatelessWidget {
  const FirmwareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firmware & OTA')),
      body: const EmptyStateWidget(
        icon: Icons.system_update_outlined,
        title: 'Firmware & OTA Management',
        subtitle:
            'Over-the-air firmware updates and device firmware management '
            'will be available in a future release.\n\n'
            'This feature requires backend infrastructure for firmware '
            'storage, versioning, and secure distribution to devices.',
      ),
    );
  }
}
