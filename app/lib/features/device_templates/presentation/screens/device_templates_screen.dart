import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../../device_studio/domain/board_definitions.dart';
import '../../../devices/domain/entities/device_entity.dart';

class DeviceTemplatesScreen extends StatelessWidget {
  const DeviceTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Device Templates')),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text(
            'Choose a hardware template to get started with device provisioning.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalLg,
          Text('Hardware Platforms', style: theme.textTheme.titleMedium),
          AppSpacing.verticalSm,
          ...Boards.all.map((board) => _BoardTemplateCard(board: board)),
          AppSpacing.verticalLg,
          Text('Connection Protocols', style: theme.textTheme.titleMedium),
          AppSpacing.verticalSm,
          _ProtocolCard(
            icon: Icons.router_outlined,
            name: 'Generic MQTT',
            platform: HardwarePlatform.genericMqtt,
            description: 'Any device that can publish/subscribe via MQTT. Connect using standard MQTT 3.1.1 or 5.0.',
            features: ['MQTT 3.1.1', 'MQTT 5.0', 'TLS', 'WebSocket'],
          ),
          _ProtocolCard(
            icon: Icons.http_outlined,
            name: 'HTTP REST',
            platform: HardwarePlatform.other,
            description: 'Devices that communicate via HTTP REST API. Send telemetry and receive commands over HTTP.',
            features: ['REST API', 'JSON', 'Bearer Auth', 'Webhooks'],
          ),
          AppSpacing.verticalLg,
          Text('Additional Platforms', style: theme.textTheme.titleMedium),
          AppSpacing.verticalSm,
          _ProtocolCard(
            icon: Icons.memory_outlined,
            name: 'Raspberry Pi',
            platform: HardwarePlatform.raspberryPi,
            description: 'Full Linux SBC. Run NexIoza agent as a system service for rich IoT gateway use cases.',
            features: ['Linux', 'GPIO', 'I2C', 'SPI', 'Wi-Fi', 'Bluetooth'],
          ),
          _ProtocolCard(
            icon: Icons.developer_board_outlined,
            name: 'Arduino',
            platform: HardwarePlatform.arduino,
            description: 'Classic Arduino boards with Ethernet or Wi-Fi shields. Use the NexIoza Arduino SDK.',
            features: ['Serial', 'Ethernet', 'Wi-Fi Shield', 'MQTT'],
          ),
          AppSpacing.verticalXl,
        ],
      ),
    );
  }
}

class _BoardTemplateCard extends StatelessWidget {
  final BoardDefinition board;

  const _BoardTemplateCard({required this.board});

  IconData get _icon => switch (board.id) {
    'esp32' => Icons.memory,
    'esp32c3' => Icons.memory,
    'esp32s3' => Icons.memory,
    'esp8266' => Icons.developer_board,
    _ => Icons.devices_other,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _icon,
                    color: scheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(board.name, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        board.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: scheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
            AppSpacing.verticalSm,
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: board.features.map((f) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    f,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
            AppSpacing.verticalXs,
            Text(
              '${board.gpioPins.length} GPIO pins  •  PlatformIO: ${board.platformioBoard}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final HardwarePlatform platform;
  final String description;
  final List<String> features;

  const _ProtocolCard({
    required this.icon,
    required this.name,
    required this.platform,
    required this.description,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: scheme.onSecondaryContainer, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: features.map((f) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          f,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
