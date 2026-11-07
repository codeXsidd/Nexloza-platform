import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;

  const StatusBadge({super.key, required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = switch (type) {
      StatusType.online => (AppColors.online, AppColors.online.withAlpha(25)),
      StatusType.offline => (
        AppColors.offline,
        AppColors.offline.withAlpha(25),
      ),
      StatusType.warning => (
        AppColors.warning,
        AppColors.warning.withAlpha(25),
      ),
      StatusType.error => (AppColors.error, AppColors.error.withAlpha(25)),
      StatusType.info => (AppColors.info, AppColors.info.withAlpha(25)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusType { online, offline, warning, error, info }
