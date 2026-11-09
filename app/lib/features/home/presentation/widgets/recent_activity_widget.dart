import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../theme/app_spacing.dart';
import '../../../notifications/domain/entities/notification_entity.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';

class RecentActivityWidget extends ConsumerWidget {
  const RecentActivityWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activity', style: theme.textTheme.titleMedium),
            AppSpacing.verticalMd,
            notificationsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => _buildEmpty(theme),
              data: (notifications) {
                if (notifications.isEmpty) return _buildEmpty(theme);
                final recent = notifications.take(5).toList();
                return Column(
                  children: recent
                      .map((n) => _ActivityTile(notification: n))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: theme.colorScheme.outline),
            AppSpacing.verticalSm,
            Text(
              'No recent activity',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Your device events and automation runs will appear here.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final AppNotification notification;

  const _ActivityTile({required this.notification});

  IconData _iconFor(NotificationCategory category) => switch (category) {
    NotificationCategory.device => Icons.devices,
    NotificationCategory.automation => Icons.auto_awesome,
    NotificationCategory.security => Icons.security,
    NotificationCategory.system => Icons.info_outline,
    NotificationCategory.alert => Icons.warning_amber,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _iconFor(notification.category),
            size: 18,
            color: theme.colorScheme.primary,
          ),
          AppSpacing.horizontalSm,
          Expanded(
            child: Text(
              notification.title,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeago.format(notification.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
