import 'package:flutter/material.dart';

import 'package:nexioza/shared/widgets/nexioza_empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No notifications to mark'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: const NexiozaEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'All caught up',
        message: "You'll see device alerts and automation events here.",
      ),
    );
  }
}
