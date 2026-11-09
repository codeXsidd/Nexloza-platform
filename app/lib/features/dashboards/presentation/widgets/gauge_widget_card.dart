import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../domain/entities/dashboard_widget_entity.dart';

class GaugeWidgetCard extends StatelessWidget {
  final DashboardWidget widget;

  const GaugeWidgetCard({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = (widget.config['value'] as num?)?.toDouble() ?? 0;
    final min = (widget.config['min'] as num?)?.toDouble() ?? 0;
    final max = (widget.config['max'] as num?)?.toDouble() ?? 100;
    final unit = widget.config['unit'] as String? ?? '';
    final normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: theme.textTheme.titleSmall),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: CustomPaint(
                    painter: _GaugePainter(
                      value: normalized,
                      color: theme.colorScheme.primary,
                      trackColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Text(
                        '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}$unit',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color trackColor;

  _GaugePainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    const startAngle = 0.75 * math.pi;
    const totalAngle = 1.5 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalAngle,
      false,
      trackPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalAngle * value,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      value != old.value || color != old.color;
}
