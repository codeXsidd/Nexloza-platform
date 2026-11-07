import 'package:flutter/material.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/device_entity.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;

  const DeviceCard({super.key, required this.device, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.memory, color: theme.colorScheme.onPrimaryContainer),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name, style: theme.textTheme.titleMedium),
                    Text(device.hardwarePlatform.displayName, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              StatusBadge(
                label: device.isOnline ? 'Online' : 'Offline',
                type: device.isOnline ? StatusType.online : StatusType.offline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
