import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/mqtt_service.dart';

class AppScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  static const _destinations = [
    _NavItem(Icons.home_outlined, Icons.home, 'Home'),
    _NavItem(Icons.folder_outlined, Icons.folder, 'Projects'),
    _NavItem(Icons.devices_other_outlined, Icons.devices_other, 'Devices'),
    _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'Automations'),
    _NavItem(Icons.smart_toy_outlined, Icons.smart_toy, 'AI'),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 600;
    final mqttStatus = ref.watch(mqttStatusProvider);

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              labelType: width >= 900
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.selected,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MqttStatusIcon(mqttStatus: mqttStatus),
              ),
              destinations: [
                for (final d in _destinations)
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
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MqttStatusBar(mqttStatus: mqttStatus),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            destinations: [
              for (final d in _destinations)
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

class _MqttStatusIcon extends StatelessWidget {
  final AsyncValue<MqttConnectionStatus> mqttStatus;

  const _MqttStatusIcon({required this.mqttStatus});

  @override
  Widget build(BuildContext context) {
    final status = mqttStatus.valueOrNull ?? MqttConnectionStatus.disconnected;
    final color = switch (status) {
      MqttConnectionStatus.connected => const Color(0xFF4CAF50),
      MqttConnectionStatus.connecting => Colors.orange,
      MqttConnectionStatus.disconnected => Colors.grey,
      MqttConnectionStatus.error => Colors.red,
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
        Colors.orange,
        Icons.sync,
        'Connecting to MQTT broker...',
      ),
      MqttConnectionStatus.error => (
        Colors.red,
        Icons.error_outline,
        'MQTT connection error',
      ),
      _ => (Colors.grey, Icons.cloud_off, 'MQTT disconnected'),
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
