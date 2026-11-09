import 'package:flutter/material.dart';

import '../../../domain/entities/dashboard_widget_entity.dart';
import '../../../domain/widget_registry.dart';

Widget _sensorCard(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data, {
  required IconData icon,
  Color? iconColor,
  Widget? trailing,
}) {
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
  final valueText = data.hasData
      ? '${data.numericValue.toStringAsFixed(widget.decimals)}${widget.unit}'
      : '--';
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor ?? theme.colorScheme.primary,
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
              if (data.isStale)
                Icon(
                  Icons.warning_amber,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
            ],
          ),
          const Spacer(),
          Text(
            valueText,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (trailing != null) trailing,
          const Spacer(),
        ],
      ),
    ),
  );
}

Color _thresholdColor(
  BuildContext context,
  DashboardWidget widget,
  double value,
) {
  final theme = Theme.of(context);
  for (final t in widget.thresholds.reversed) {
    final threshold = (t['value'] as num?)?.toDouble();
    if (threshold != null && value >= threshold) {
      final colorStr = t['color'] as String?;
      if (colorStr != null) {
        final parsed = int.tryParse(colorStr.replaceFirst('#', ''), radix: 16);
        if (parsed != null) {
          return Color(parsed | 0xFF000000);
        }
      }
    }
  }
  return theme.colorScheme.primary;
}

// 1. Temperature
Widget buildTemperatureCard(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final color = data.hasData
      ? _thresholdColor(context, widget, data.numericValue)
      : null;
  return _sensorCard(
    context,
    widget,
    data,
    icon: Icons.thermostat,
    iconColor: color,
  );
}

// 2. Humidity
Widget buildHumidityCard(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  return _sensorCard(context, widget, data, icon: Icons.water_drop);
}

// 3. Pressure
Widget buildPressureCard(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  return _sensorCard(context, widget, data, icon: Icons.speed);
}

// 4. Soil Moisture
Widget buildSoilMoistureCard(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  final pct = data.hasData ? data.numericValue.clamp(0, 100) / 100 : 0.0;
  return _sensorCard(
    context,
    widget,
    data,
    icon: Icons.grass,
    trailing: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: LinearProgressIndicator(
        value: pct,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: pct > 0.6
            ? Colors.green
            : pct > 0.3
            ? Colors.orange
            : Colors.red,
      ),
    ),
  );
}

// 5. Water Level
Widget buildWaterLevelCard(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  return _sensorCard(context, widget, data, icon: Icons.waves);
}

// 6. Light Intensity
Widget buildLightCard(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  return _sensorCard(context, widget, data, icon: Icons.wb_sunny);
}

// 7. Motion
Widget buildMotionCard(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  final detected = data.boolValue;
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_run,
                size: 18,
                color: detected
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline,
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
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: detected
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                detected ? 'Motion Detected' : 'No Motion',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
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

// 8. Voltage
Widget buildVoltageCard(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  return _sensorCard(context, widget, data, icon: Icons.bolt);
}

// 9. Power
Widget buildPowerCard(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  return _sensorCard(context, widget, data, icon: Icons.electrical_services);
}

// 10. Battery
Widget buildBatteryCard(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  final pct = data.hasData ? data.numericValue.clamp(0, 100) : 0.0;
  final batteryIcon = pct > 80
      ? Icons.battery_full
      : pct > 50
      ? Icons.battery_5_bar
      : pct > 20
      ? Icons.battery_3_bar
      : Icons.battery_1_bar;
  final color = pct > 20 ? theme.colorScheme.primary : theme.colorScheme.error;
  return _sensorCard(
    context,
    widget,
    data,
    icon: batteryIcon,
    iconColor: color,
  );
}
