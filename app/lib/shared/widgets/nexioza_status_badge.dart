import 'package:flutter/material.dart';

class NexiozaStatusBadge extends StatelessWidget {
  const NexiozaStatusBadge({
    required this.label,
    required this.color,
    super.key,
  });

  const NexiozaStatusBadge.online({super.key})
    : label = 'Online',
      color = const Color(0xFF16A34A);

  const NexiozaStatusBadge.offline({super.key})
    : label = 'Offline',
      color = const Color(0xFF9CA3AF);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
