import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../data/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';

import 'package:timeago/timeago.dart' as timeago;

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) async {
    final repo = ref.watch(notificationRepositoryProvider);
    final result = await repo.getNotifications();
    return result.when(
      success: (data) => data,
      failure: (_) => <AppNotification>[],
    );
  },
);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notifications),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllAsRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none,
              title: AppStrings.noNotifications,
              subtitle: AppStrings.noNotificationsHint,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationTile(
                  notification: n,
                  onTap: () async {
                    if (!n.isRead) {
                      await ref
                          .read(notificationRepositoryProvider)
                          .markAsRead(n.id);
                      ref.invalidate(notificationsProvider);
                    }
                  },
                  onDismiss: () async {
                    await ref
                        .read(notificationRepositoryProvider)
                        .deleteNotification(n.id);
                    ref.invalidate(notificationsProvider);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  IconData _iconForCategory(NotificationCategory category) {
    return switch (category) {
      NotificationCategory.device => Icons.devices,
      NotificationCategory.automation => Icons.auto_awesome,
      NotificationCategory.security => Icons.security,
      NotificationCategory.system => Icons.info_outline,
      NotificationCategory.alert => Icons.warning_amber,
    };
  }

  Color _colorForSeverity(NotificationSeverity severity, ThemeData theme) {
    return switch (severity) {
      NotificationSeverity.info => theme.colorScheme.primary,
      NotificationSeverity.warning => Colors.orange,
      NotificationSeverity.critical => theme.colorScheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _colorForSeverity(
            notification.severity,
            theme,
          ).withAlpha(30),
          child: Icon(
            _iconForCategory(notification.category),
            color: _colorForSeverity(notification.severity, theme),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          notification.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          timeago.format(notification.createdAt),
          style: theme.textTheme.bodySmall,
        ),
        onTap: onTap,
        tileColor: notification.isRead
            ? null
            : theme.colorScheme.primaryContainer.withAlpha(30),
      ),
    );
  }
}
