import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../domain/entities/dashboard_widget_entity.dart';

class ChartWidgetCard extends StatelessWidget {
  final DashboardWidget widget;

  const ChartWidgetCard({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBar = widget.widgetType == DashboardWidgetType.barChart;

    final dataPoints = _parseDataPoints();

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: theme.textTheme.titleSmall),
            AppSpacing.verticalSm,
            Expanded(
              child: dataPoints.isEmpty
                  ? Center(
                      child: Text(
                        'No data yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : CustomPaint(
                      size: Size.infinite,
                      painter: isBar
                          ? _BarChartPainter(
                              data: dataPoints,
                              color: theme.colorScheme.primary,
                              gridColor:
                                  theme.colorScheme.surfaceContainerHighest,
                            )
                          : _LineChartPainter(
                              data: dataPoints,
                              color: theme.colorScheme.primary,
                              gridColor:
                                  theme.colorScheme.surfaceContainerHighest,
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _parseDataPoints() {
    final raw = widget.config['data'];
    if (raw is List) {
      return raw.map((e) => (e as num).toDouble()).toList();
    }
    return [];
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final Color gridColor;

  _LineChartPainter({
    required this.data,
    required this.color,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withAlpha(30)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height - (data[i] - minVal) / range * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => data != old.data;
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final Color gridColor;

  _BarChartPainter({
    required this.data,
    required this.color,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final barWidth = size.width / data.length * 0.7;
    final gap = size.width / data.length * 0.3;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final barHeight = data[i] / maxVal * size.height;
      final x = i * (barWidth + gap) + gap / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => data != old.data;
}
