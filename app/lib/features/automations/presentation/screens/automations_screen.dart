import 'package:flutter/material.dart';

import 'package:nexioza/shared/widgets/nexioza_empty_state.dart';

class AutomationsScreen extends StatelessWidget {
  const AutomationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automations'),
      ),
      body: NexiozaEmptyState(
        icon: Icons.bolt_rounded,
        title: 'No automations',
        message: 'Set up rules to automate your IoT devices.',
        actionLabel: 'Create Automation',
        onAction: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coming in Phase 4'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}
