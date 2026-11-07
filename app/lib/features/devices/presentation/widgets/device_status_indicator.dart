import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class DeviceStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;

  const DeviceStatusIndicator({
    super.key,
    required this.isOnline,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.online : AppColors.offline,
        shape: BoxShape.circle,
        boxShadow: isOnline
            ? [BoxShadow(color: AppColors.online.withAlpha(100), blurRadius: 6)]
            : null,
      ),
    );
  }
}
