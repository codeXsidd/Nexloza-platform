import 'package:flutter/material.dart';

import '../../../domain/entities/dashboard_widget_entity.dart';
import '../../../domain/widget_registry.dart';

// 1. Machine Status
Widget buildMachineStatus(
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
  final status = data.stringValue.toLowerCase();
  Color statusColor;
  IconData statusIcon;
  if (status == 'running' || status == 'on') {
    statusColor = Colors.green;
    statusIcon = Icons.play_circle;
  } else if (status == 'idle' || status == 'standby') {
    statusColor = Colors.orange;
    statusIcon = Icons.pause_circle;
  } else if (status == 'error' || status == 'fault') {
    statusColor = theme.colorScheme.error;
    statusIcon = Icons.error;
  } else {
    statusColor = theme.colorScheme.outline;
    statusIcon = Icons.stop_circle;
  }
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.precision_manufacturing,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Icon(statusIcon, size: 28, color: statusColor),
              const SizedBox(width: 8),
              Text(
                data.stringValue,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (data.deviceInfo.containsKey('uptime'))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Uptime: ${data.deviceInfo['uptime']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          const Spacer(),
        ],
      ),
    ),
  );
}

// 2. Tank Level (SCADA-style)
Widget buildTankLevel(
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
  final pct = data.hasData ? data.numericValue.clamp(0, 100) / 100 : 0.0;
  final color = pct > 0.8
      ? Colors.blue
      : pct > 0.3
      ? theme.colorScheme.primary
      : Colors.orange;
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
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _TankPainter(
                      level: pct,
                      color: color,
                      borderColor: theme.colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (data.hasData)
                      Text(
                        '${data.numericValue.toStringAsFixed(widget.decimals)}${widget.unit}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// 3. Motor Status
Widget buildMotorStatus(
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
  final running = data.boolValue;
  final rpm = data.deviceInfo['rpm'] as num?;
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: running ? Colors.green : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                running ? 'Running' : 'Stopped',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: running ? Colors.green : theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          if (rpm != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${rpm.toStringAsFixed(0)} RPM',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          const Spacer(),
        ],
      ),
    ),
  );
}

// 4. Equipment Status
Widget buildEquipmentStatus(
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
  final status = data.stringValue.toLowerCase();
  final isOperational =
      status == 'operational' || status == 'ok' || status == 'running';
  final needsMaintenance = status == 'maintenance' || status == 'service';
  Color color;
  IconData icon;
  if (isOperational) {
    color = Colors.green;
    icon = Icons.check_circle;
  } else if (needsMaintenance) {
    color = Colors.orange;
    icon = Icons.build;
  } else {
    color = theme.colorScheme.error;
    icon = Icons.warning;
  }
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.construction,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.stringValue,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    ),
  );
}

// 5. Alarm Panel
Widget buildAlarmPanel(
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
  final alarms = <Map<String, dynamic>>[];
  if (data.currentValue is List) {
    for (final item in data.currentValue as List) {
      if (item is Map<String, dynamic>) {
        alarms.add(item);
      }
    }
  }
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notification_important,
                size: 18,
                color: alarms.isNotEmpty
                    ? theme.colorScheme.error
                    : Colors.green,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: alarms.isNotEmpty
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${alarms.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: alarms.isNotEmpty
                        ? theme.colorScheme.error
                        : theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (alarms.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 32,
                      color: Colors.green.withAlpha(180),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All Clear',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: alarms.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final alarm = alarms[i];
                  final severity = (alarm['severity'] as String? ?? 'warning')
                      .toLowerCase();
                  final color = severity == 'critical'
                      ? theme.colorScheme.error
                      : Colors.orange;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alarm['message'] as String? ?? 'Alarm',
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );
}

// --- Tank painter ---

class _TankPainter extends CustomPainter {
  final double level;
  final Color color;
  final Color borderColor;
  _TankPainter({
    required this.level,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final fillHeight = size.height * level;
    final fillRect = Rect.fromLTWH(
      2,
      size.height - fillHeight + 2,
      size.width - 4,
      fillHeight - 4,
    );
    if (fillRect.height > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, const Radius.circular(4)),
        Paint()..color = color.withAlpha(180),
      );
    }
  }

  @override
  bool shouldRepaint(_TankPainter old) =>
      old.level != level || old.color != color;
}
