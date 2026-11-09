import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../theme/app_spacing.dart';
import '../widgets/project_summary_card.dart';
import '../widgets/device_status_card.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/recent_activity_widget.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../../devices/presentation/providers/device_provider.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final userName =
        auth.user?.userMetadata?['full_name'] as String? ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $userName', style: theme.textTheme.titleLarge),
            Text(
              'Welcome to Nexloza',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.pushNamed(RouteNames.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed(RouteNames.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(projectsProvider);
          ref.invalidate(devicesProvider);
          ref.invalidate(notificationsProvider);
        },
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: const [
            ProjectSummaryCard(),
            AppSpacing.verticalMd,
            DeviceStatusCard(),
            AppSpacing.verticalMd,
            QuickActionsWidget(),
            AppSpacing.verticalMd,
            RecentActivityWidget(),
          ],
        ),
      ),
    );
  }
}
