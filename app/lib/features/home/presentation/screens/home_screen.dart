import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/nex_section_header.dart';
import '../../../../core/design_system/nex_stat_card.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../routing/route_names.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../devices/presentation/providers/device_provider.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/recent_activity_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final userName =
        auth.user?.userMetadata?['full_name'] as String? ?? 'there';
    final devicesAsync = ref.watch(devicesProvider);
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $userName', style: theme.textTheme.titleLarge),
            Text(
              'Welcome to NexIoza',
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
          if (!AppBreakpoints.isDesktop(context))
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
          padding: AppBreakpoints.screenPadding(context),
          children: [
            NexSectionHeader(
              title: 'Overview',
              actionLabel: 'All Devices',
              actionIcon: Icons.arrow_forward,
              onAction: () => context.go('/devices'),
            ),
            AppSpacing.verticalSm,
            ResponsiveGrid(
              children: [
                NexStatCard(
                  label: 'Total Devices',
                  value: devicesAsync.when(
                    data: (d) => '${d.length}',
                    loading: () => '...',
                    error: (_, __) => '--',
                  ),
                  icon: Icons.devices_other,
                  iconColor: AppColors.primary,
                  onTap: () => context.go('/devices'),
                ),
                NexStatCard(
                  label: 'Online',
                  value: devicesAsync.when(
                    data: (d) => '${d.where((x) => x.isOnline).length}',
                    loading: () => '...',
                    error: (_, __) => '--',
                  ),
                  icon: Icons.wifi,
                  iconColor: AppColors.success,
                ),
                NexStatCard(
                  label: 'Offline',
                  value: devicesAsync.when(
                    data: (d) => '${d.where((x) => !x.isOnline).length}',
                    loading: () => '...',
                    error: (_, __) => '--',
                  ),
                  icon: Icons.wifi_off,
                  iconColor: AppColors.error,
                ),
                NexStatCard(
                  label: 'Projects',
                  value: projectsAsync.when(
                    data: (p) => '${p.length}',
                    loading: () => '...',
                    error: (_, __) => '--',
                  ),
                  icon: Icons.folder,
                  iconColor: AppColors.secondary,
                  onTap: () => context.pushNamed(RouteNames.projects),
                ),
              ],
            ),
            AppSpacing.verticalLg,
            const QuickActionsWidget(),
            AppSpacing.verticalLg,
            const RecentActivityWidget(),
            AppSpacing.verticalXl,
          ],
        ),
      ),
    );
  }
}
