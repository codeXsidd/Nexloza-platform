import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/route_names.dart';
import '../../theme/app_colors.dart';

class WebConsoleSidebar extends StatefulWidget {
  final int currentShellIndex;
  final void Function(int) onShellIndexChanged;

  const WebConsoleSidebar({
    super.key,
    required this.currentShellIndex,
    required this.onShellIndexChanged,
  });

  @override
  State<WebConsoleSidebar> createState() => _WebConsoleSidebarState();
}

class _WebConsoleSidebarState extends State<WebConsoleSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentPath = GoRouterState.of(context).matchedLocation;
    final width = _isCollapsed ? 72.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      color: scheme.surface,
      child: Column(
        children: [
          _SidebarHeader(
            isCollapsed: _isCollapsed,
            onToggle: () => setState(() => _isCollapsed = !_isCollapsed),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  label: 'Overview',
                  isSelected: currentPath == '/home',
                  isCollapsed: _isCollapsed,
                  onTap: () => widget.onShellIndexChanged(0),
                ),
                _SidebarItem(
                  icon: Icons.business_outlined,
                  selectedIcon: Icons.business,
                  label: 'Organizations',
                  isSelected: currentPath.startsWith('/organizations'),
                  isCollapsed: _isCollapsed,
                  onTap: () => context.pushNamed(RouteNames.organizations),
                ),
                _SidebarItem(
                  icon: Icons.folder_outlined,
                  selectedIcon: Icons.folder,
                  label: 'Projects',
                  isSelected: currentPath.startsWith('/projects'),
                  isCollapsed: _isCollapsed,
                  onTap: () => context.pushNamed(RouteNames.projects),
                ),
                const _SidebarDivider(),
                _SidebarSectionLabel(
                  label: 'Device Management',
                  isCollapsed: _isCollapsed,
                ),
                _SidebarItem(
                  icon: Icons.devices_other_outlined,
                  selectedIcon: Icons.devices_other,
                  label: 'Devices',
                  isSelected:
                      currentPath == '/devices' &&
                      widget.currentShellIndex == 1,
                  isCollapsed: _isCollapsed,
                  onTap: () => widget.onShellIndexChanged(1),
                ),
                _SidebarItem(
                  icon: Icons.description_outlined,
                  selectedIcon: Icons.description,
                  label: 'Device Templates',
                  isSelected: currentPath.startsWith('/device-templates'),
                  isCollapsed: _isCollapsed,
                  onTap: () => context.pushNamed(RouteNames.deviceTemplates),
                ),
                _SidebarItem(
                  icon: Icons.memory_outlined,
                  selectedIcon: Icons.memory,
                  label: 'Virtual Devices',
                  isSelected: currentPath.startsWith('/virtual-devices'),
                  isCollapsed: _isCollapsed,
                  onTap: () => context.pushNamed(RouteNames.virtualDevices),
                ),
                const _SidebarDivider(),
                _SidebarSectionLabel(
                  label: 'Intelligence',
                  isCollapsed: _isCollapsed,
                ),
                _SidebarItem(
                  icon: Icons.dashboard_customize_outlined,
                  selectedIcon: Icons.dashboard_customize,
                  label: 'Dashboard Builder',
                  isSelected: currentPath.startsWith('/dashboards'),
                  isCollapsed: _isCollapsed,
                  onTap: () => context.pushNamed(RouteNames.dashboards),
                ),
                _SidebarItem(
                  icon: Icons.analytics_outlined,
                  selectedIcon: Icons.analytics,
                  label: 'Telemetry & Analytics',
                  isSelected: currentPath == '/analytics',
                  isCollapsed: _isCollapsed,
                  onTap: () => widget.onShellIndexChanged(3),
                ),
                _SidebarItem(
                  icon: Icons.auto_awesome_outlined,
                  selectedIcon: Icons.auto_awesome,
                  label: 'Automation & Rules',
                  isSelected:
                      currentPath == '/automations' ||
                      currentPath.startsWith('/rules'),
                  isCollapsed: _isCollapsed,
                  onTap: () => widget.onShellIndexChanged(2),
                ),
                _SidebarItem(
                  icon: Icons.warning_amber_outlined,
                  selectedIcon: Icons.warning_amber,
                  label: 'Alerts & Notifications',
                  isSelected:
                      currentPath.startsWith('/alarms') ||
                      currentPath.startsWith('/notifications'),
                  isCollapsed: _isCollapsed,
                  onTap: () => context.pushNamed(RouteNames.alarms),
                ),
                const _SidebarDivider(),
                _SidebarSectionLabel(
                  label: 'Platform',
                  isCollapsed: _isCollapsed,
                ),
                _SidebarItem(
                  icon: Icons.extension_outlined,
                  selectedIcon: Icons.extension,
                  label: 'Integrations',
                  isSelected: currentPath.startsWith('/integrations'),
                  isCollapsed: _isCollapsed,
                  onTap: () => context.pushNamed(RouteNames.integrations),
                ),
                _SidebarItem(
                  icon: Icons.system_update_outlined,
                  selectedIcon: Icons.system_update,
                  label: 'Firmware & OTA',
                  isSelected: currentPath.startsWith('/firmware'),
                  isCollapsed: _isCollapsed,
                  onTap: () => context.pushNamed(RouteNames.firmware),
                ),
                _SidebarItem(
                  icon: Icons.code_outlined,
                  selectedIcon: Icons.code,
                  label: 'API & Developer Tools',
                  isSelected: currentPath.startsWith('/developer'),
                  isCollapsed: _isCollapsed,
                  onTap: () => context.pushNamed(RouteNames.developerTools),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _SidebarItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Settings',
            isSelected: currentPath == '/settings',
            isCollapsed: _isCollapsed,
            onTap: () => widget.onShellIndexChanged(4),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  const _SidebarHeader({required this.isCollapsed, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 56,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'NexIoza',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
            const Spacer(),
            IconButton(
              icon: Icon(
                isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                size: 20,
              ),
              onPressed: onToggle,
              visualDensity: VisualDensity.compact,
              tooltip: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 8 : 12,
        vertical: 1,
      ),
      child: Material(
        color: isSelected
            ? scheme.primaryContainer.withAlpha(80)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 12,
              vertical: 10,
            ),
            child: isCollapsed
                ? Tooltip(
                    message: label,
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      size: 22,
                      color: isSelected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        isSelected ? selectedIcon : icon,
                        size: 20,
                        color: isSelected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Divider(height: 1),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  final String label;
  final bool isCollapsed;

  const _SidebarSectionLabel({required this.label, required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) return const SizedBox(height: 8);

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant.withAlpha(160),
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
