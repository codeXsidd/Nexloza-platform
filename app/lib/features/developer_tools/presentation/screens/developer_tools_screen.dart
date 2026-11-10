import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../theme/app_spacing.dart';

class DeveloperToolsScreen extends StatelessWidget {
  const DeveloperToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('API & Developer Tools')),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(
            'Tools and resources for device integration and platform development.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalLg,
          _SectionLabel('Credentials & Keys', theme),
          ListTile(
            leading: _TileIcon(Icons.vpn_key_outlined, scheme),
            title: const Text('API Keys'),
            subtitle: const Text('Manage device API credentials and tokens'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.pushNamed(RouteNames.apiKeys),
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: _TileIcon(Icons.lock_outlined, scheme),
            title: const Text('Device Credentials'),
            subtitle: const Text(
              'Provisioned via device pairing or the add-device flow',
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.pushNamed(RouteNames.devices),
          ),
          AppSpacing.verticalLg,
          _SectionLabel('MQTT', theme),
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.router_outlined, color: scheme.primary),
                      const SizedBox(width: 12),
                      Text('MQTT Broker', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  AppSpacing.verticalSm,
                  _InfoRow('Protocol', 'MQTT 3.1.1 / 5.0', theme),
                  _InfoRow('Default Port', '1883 (TCP) / 8883 (TLS)', theme),
                  _InfoRow('WebSocket', '8083 (WS) / 8084 (WSS)', theme),
                  AppSpacing.verticalSm,
                  Text(
                    'Broker connection details are configured in your '
                    'project environment. Device credentials are issued '
                    'during the pairing flow.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.verticalSm,
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.topic_outlined, color: scheme.primary),
                      const SizedBox(width: 12),
                      Text('Topic Format', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  AppSpacing.verticalSm,
                  _TopicRow(
                    'Telemetry',
                    'v1/{org}/{project}/{device}/telemetry',
                    theme,
                  ),
                  _TopicRow(
                    'Commands',
                    'v1/{org}/{project}/{device}/cmd',
                    theme,
                  ),
                  _TopicRow(
                    'Status',
                    'v1/{org}/{project}/{device}/status',
                    theme,
                  ),
                  _TopicRow(
                    'Events',
                    'v1/{org}/{project}/{device}/events',
                    theme,
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.verticalLg,
          _SectionLabel('Development', theme),
          ListTile(
            leading: _TileIcon(Icons.code_outlined, scheme),
            title: const Text('Device Studio'),
            subtitle: const Text('Code generator for firmware sketches'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.pushNamed(RouteNames.deviceStudio),
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: _TileIcon(Icons.extension_outlined, scheme),
            title: const Text('Integrations & Webhooks'),
            subtitle: const Text('Configure third-party integrations'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.pushNamed(RouteNames.integrations),
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: _TileIcon(Icons.description_outlined, scheme),
            title: const Text('Device Templates'),
            subtitle: const Text('Hardware platform templates and specs'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.pushNamed(RouteNames.deviceTemplates),
          ),
          AppSpacing.verticalXl,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const _SectionLabel(this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final ColorScheme scheme;

  const _TileIcon(this.icon, this.scheme);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: scheme.onPrimaryContainer, size: 20),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _InfoRow(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final String label;
  final String topic;
  final ThemeData theme;

  const _TopicRow(this.label, this.topic, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                topic,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
