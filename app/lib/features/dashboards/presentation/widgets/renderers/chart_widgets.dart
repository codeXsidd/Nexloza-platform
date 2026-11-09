import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/entities/dashboard_widget_entity.dart';
import '../../../domain/widget_registry.dart';

// 1. Line Chart
Widget buildLineChart(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  return _ChartCard(widget: widget, data: data, chartType: _ChartType.line);
}

// 2. Area Chart
Widget buildAreaChart(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  return _ChartCard(widget: widget, data: data, chartType: _ChartType.area);
}

// 3. Bar Chart
Widget buildBarChart(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  return _ChartCard(widget: widget, data: data, chartType: _ChartType.bar);
}

// 4. Gauge
Widget buildGauge(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  if (data.isLoading) {
    return Card(
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
  final value = data.numericValue;
  final min = widget.rangeMin;
  final max = widget.rangeMax;
  final pct = max > min ? ((value - min) / (max - min)).clamp(0.0, 1.0) : 0.0;
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              painter: _GaugePainter(
                value: pct,
                color: theme.colorScheme.primary,
                trackColor: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(
                  '${value.toStringAsFixed(widget.decimals)}${widget.unit}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
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

// 5. Radial Gauge
Widget buildRadialGauge(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  if (data.isLoading) {
    return Card(
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
  final value = data.numericValue;
  final min = widget.rangeMin;
  final max = widget.rangeMax;
  final pct = max > min ? ((value - min) / (max - min)).clamp(0.0, 1.0) : 0.0;
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: theme.colorScheme.primary,
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// 6. Progress Bar
Widget buildProgressBar(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  if (data.isLoading) {
    return Card(
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
  final value = data.numericValue;
  final min = widget.rangeMin;
  final max = widget.rangeMax;
  final pct = max > min ? ((value - min) / (max - min)).clamp(0.0, 1.0) : 0.0;
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${value.toStringAsFixed(widget.decimals)}${widget.unit}',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(min.toStringAsFixed(0), style: theme.textTheme.labelSmall),
              Text(max.toStringAsFixed(0), style: theme.textTheme.labelSmall),
            ],
          ),
          const Spacer(),
        ],
      ),
    ),
  );
}

// 7. Real-time Chart
Widget buildRealtimeChart(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  return _ChartCard(
    widget: widget,
    data: data,
    chartType: _ChartType.line,
    isRealtime: true,
  );
}

// 8. Min/Max/Avg
Widget buildMinMaxAvg(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  if (data.isLoading) {
    return Card(
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
  double minVal = 0, maxVal = 0, avgVal = 0;
  if (data.history.isNotEmpty) {
    minVal = data.history.map((e) => e.value).reduce(math.min);
    maxVal = data.history.map((e) => e.value).reduce(math.max);
    avgVal =
        data.history.map((e) => e.value).reduce((a, b) => a + b) /
        data.history.length;
  }
  final dec = widget.decimals;
  final u = widget.unit;
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatColumn(
                label: 'Min',
                value: '${minVal.toStringAsFixed(dec)}$u',
                color: Colors.blue,
                theme: theme,
              ),
              _StatColumn(
                label: 'Avg',
                value: '${avgVal.toStringAsFixed(dec)}$u',
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              _StatColumn(
                label: 'Max',
                value: '${maxVal.toStringAsFixed(dec)}$u',
                color: Colors.red,
                theme: theme,
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    ),
  );
}

// --- Helpers ---

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

enum _ChartType { line, area, bar }

class _ChartCard extends StatelessWidget {
  final DashboardWidget widget;
  final WidgetDataState data;
  final _ChartType chartType;
  final bool isRealtime;
  const _ChartCard({
    required this.widget,
    required this.data,
    required this.chartType,
    this.isRealtime = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isLoading) {
      return Card(
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isRealtime)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: data.isStale
                          ? theme.colorScheme.error
                          : Colors.green,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: data.history.isEmpty
                  ? Center(
                      child: Text(
                        'No data',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  : CustomPaint(
                      size: Size.infinite,
                      painter: _SimpleChartPainter(
                        points: data.history.map((e) => e.value).toList(),
                        color: theme.colorScheme.primary,
                        type: chartType,
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
    final center = Offset(size.width / 2, size.height * 0.65);
    final radius = math.min(size.width, size.height) * 0.4;
    const startAngle = math.pi * 0.8;
    const sweepTotal = math.pi * 1.4;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * value,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

class _SimpleChartPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  final _ChartType type;
  _SimpleChartPainter({
    required this.points,
    required this.color,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final minY = points.reduce(math.min);
    final maxY = points.reduce(math.max);
    final range = maxY - minY == 0 ? 1.0 : maxY - minY;
    final stepX = points.length > 1
        ? size.width / (points.length - 1)
        : size.width;

    if (type == _ChartType.bar) {
      final barWidth = (size.width / points.length) * 0.7;
      final barPaint = Paint()..color = color;
      for (int i = 0; i < points.length; i++) {
        final h = ((points[i] - minY) / range) * size.height * 0.9;
        final x =
            (size.width / points.length) * i +
            (size.width / points.length - barWidth) / 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, size.height - h, barWidth, h),
            const Radius.circular(2),
          ),
          barPaint,
        );
      }
      return;
    }

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = stepX * i;
      final y = size.height - ((points[i] - minY) / range) * size.height * 0.9;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (type == _ChartType.area) {
      final areaPath = Path.from(path)
        ..lineTo(stepX * (points.length - 1), size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(areaPath, Paint()..color = color.withAlpha(40));
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SimpleChartPainter old) =>
      old.points != points || old.color != color;
}
