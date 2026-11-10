import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum IntegrationStatus {
  connected,
  configured,
  available,
  disconnected,
  requiresCredentials,
  requiresExternalSetup,
  comingSoon,
  notImplemented,
}

class NexIntegrationCard extends StatelessWidget {
  final String name;
  final String? description;
  final IconData icon;
  final IntegrationStatus status;
  final VoidCallback? onTap;

  const NexIntegrationCard({
    super.key,
    required this.name,
    this.description,
    required this.icon,
    required this.status,
    this.onTap,
  });

  Color _statusColor() => switch (status) {
    IntegrationStatus.connected => AppColors.success,
    IntegrationStatus.configured => AppColors.info,
    IntegrationStatus.available => AppColors.primary,
    IntegrationStatus.disconnected => AppColors.offline,
    IntegrationStatus.requiresCredentials => AppColors.warning,
    IntegrationStatus.requiresExternalSetup => AppColors.warning,
    IntegrationStatus.comingSoon => AppColors.offline,
    IntegrationStatus.notImplemented => AppColors.offline,
  };

  String _statusLabel() => switch (status) {
    IntegrationStatus.connected => 'Connected',
    IntegrationStatus.configured => 'Configured',
    IntegrationStatus.available => 'Available',
    IntegrationStatus.disconnected => 'Disconnected',
    IntegrationStatus.requiresCredentials => 'Requires Credentials',
    IntegrationStatus.requiresExternalSetup => 'Requires Setup',
    IntegrationStatus.comingSoon => 'Coming Soon',
    IntegrationStatus.notImplemented => 'Not Available',
  };

  IconData _statusIcon() => switch (status) {
    IntegrationStatus.connected => Icons.check_circle,
    IntegrationStatus.configured => Icons.settings,
    IntegrationStatus.available => Icons.add_circle_outline,
    IntegrationStatus.disconnected => Icons.cancel_outlined,
    IntegrationStatus.requiresCredentials => Icons.key,
    IntegrationStatus.requiresExternalSetup => Icons.open_in_new,
    IntegrationStatus.comingSoon => Icons.schedule,
    IntegrationStatus.notImplemented => Icons.block,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = _statusColor();
    final isInteractive =
        status != IntegrationStatus.notImplemented &&
        status != IntegrationStatus.comingSoon;

    return Card(
      child: InkWell(
        onTap: isInteractive ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 22),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(), size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel(),
                          style: textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(name, style: textTheme.titleSmall),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
