import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/services/mqtt_service.dart';
import '../../theme/app_colors.dart';
import 'web_console_sidebar.dart';

class AppScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  static const _mobileDestinations = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.devices_other_outlined, Icons.devices_other, 'Devices'),
    _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'Automation'),
    _NavItem(Icons.analytics_outlined, Icons.analytics, 'Analytics'),
    _NavItem(Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  void _onMobileTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = AppBreakpoints.of(context);
    final mqttStatus = ref.watch(mqttStatusProvider);

    if (screenSize == ScreenSize.desktop ||
        screenSize == ScreenSize.wideDesktop) {
      return _DesktopLayout(
        navigationShell: navigationShell,
        mqttStatus: mqttStatus,
      );
    }

    if (screenSize == ScreenSize.tablet) {
      return _TabletLayout(
        navigationShell: navigationShell,
        mqttStatus: mqttStatus,
        destinations: _mobileDestinations,
        onTap: _onMobileTap,
      );
    }

    return _MobileLayout(
      navigationShell: navigationShell,
      mqttStatus: mqttStatus,
      destinations: _mobileDestinations,
      onTap: _onMobileTap,
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final AsyncValue<MqttConnectionStatus> mqttStatus;
  final List<_NavItem> destinations;
  final void Function(int) onTap;

  const _MobileLayout({
    required this.navigationShell,
    required this.mqttStatus,
    required this.destinations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MqttStatusBar(mqttStatus: mqttStatus),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: onTap,
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabletLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final AsyncValue<MqttConnectionStatus> mqttStatus;
  final List<_NavItem> destinations;
  final void Function(int) onTap;

  const _TabletLayout({
    required this.navigationShell,
    required this.mqttStatus,
    required this.destinations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _MqttStatusBar(mqttStatus: mqttStatus),
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: onTap,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MqttStatusIcon(mqttStatus: mqttStatus),
                  ),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final AsyncValue<MqttConnectionStatus> mqttStatus;

  const _DesktopLayout({
    required this.navigationShell,
    required this.mqttStatus,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          _MqttStatusBar(mqttStatus: mqttStatus),
          Expanded(
            child: Row(
              children: [
                WebConsoleSidebar(
                  currentShellIndex: navigationShell.currentIndex,
                  onShellIndexChanged: (index) {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: scheme.outlineVariant,
                ),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MqttStatusIcon extends StatelessWidget {
  final AsyncValue<MqttConnectionStatus> mqttStatus;

  const _MqttStatusIcon({required this.mqttStatus});

  @override
  Widget build(BuildContext context) {
    final status = mqttStatus.valueOrNull ?? MqttConnectionStatus.disconnected;
    final color = switch (status) {
      MqttConnectionStatus.connected => AppColors.online,
      MqttConnectionStatus.connecting => AppColors.warning,
      MqttConnectionStatus.disconnected => AppColors.offline,
      MqttConnectionStatus.error => AppColors.error,
    };
    final tooltip = switch (status) {
      MqttConnectionStatus.connected => 'MQTT Connected',
      MqttConnectionStatus.connecting => 'MQTT Connecting...',
      MqttConnectionStatus.disconnected => 'MQTT Disconnected',
      MqttConnectionStatus.error => 'MQTT Error',
    };

    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.sensors,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MqttStatusBar extends StatelessWidget {
  final AsyncValue<MqttConnectionStatus> mqttStatus;

  const _MqttStatusBar({required this.mqttStatus});

  @override
  Widget build(BuildContext context) {
    final status = mqttStatus.valueOrNull ?? MqttConnectionStatus.disconnected;
    if (status == MqttConnectionStatus.connected) {
      return const SizedBox.shrink();
    }

    final (color, icon, text) = switch (status) {
      MqttConnectionStatus.connecting => (
        AppColors.warning,
        Icons.sync,
        'Connecting to MQTT broker...',
      ),
      MqttConnectionStatus.error => (
        AppColors.error,
        Icons.error_outline,
        'MQTT connection error',
      ),
      _ => (AppColors.offline, Icons.cloud_off, 'MQTT disconnected'),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: color.withValues(alpha: 0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}
