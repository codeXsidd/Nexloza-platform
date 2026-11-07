import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';

class DeviceStatusCard extends StatelessWidget {
  const DeviceStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices_other, color: theme.colorScheme.primary),
                AppSpacing.horizontalSm,
                Text('Devices', style: theme.textTheme.titleMedium),
              ],
            ),
            AppSpacing.verticalMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DeviceCount(count: 0, label: 'Total', color: theme.colorScheme.primary),
                _DeviceCount(count: 0, label: 'Online', color: AppColors.online),
                _DeviceCount(count: 0, label: 'Offline', color: AppColors.offline),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCount extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _DeviceCount({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
