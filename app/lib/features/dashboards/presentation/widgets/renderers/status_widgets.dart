import 'package:flutter/material.dart';

import '../../../domain/entities/dashboard_widget_entity.dart';
import '../../../domain/widget_registry.dart';

// 1. Device Status
Widget buildDeviceStatus(
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
  final online = data.boolValue;
  final deviceName = data.deviceInfo['name'] as String? ?? widget.title;
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.devices_other,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  deviceName,
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
                  color: online ? Colors.green : theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                online ? 'Online' : 'Offline',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: online ? Colors.green : theme.colorScheme.error,
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

// 2. MQTT Status
Widget buildMqttStatus(
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
  final connected = data.boolValue;
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wifi,
                size: 18,
                color: connected ? Colors.green : theme.colorScheme.error,
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
          Text(
            connected ? 'Connected' : 'Disconnected',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: connected ? Colors.green : theme.colorScheme.error,
            ),
          ),
          if (data.deviceInfo.containsKey('broker'))
            Text(
              data.deviceInfo['broker'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          const Spacer(),
        ],
      ),
    ),
  );
}

// 3. Device Health
Widget buildDeviceHealth(
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
  final health = data.numericValue.clamp(0, 100);
  final color = health > 70
      ? Colors.green
      : health > 40
      ? Colors.orange
      : theme.colorScheme.error;
  final label = health > 70
      ? 'Healthy'
      : health > 40
      ? 'Warning'
      : 'Critical';
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart, size: 18, color: color),
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
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: health / 100,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
          const Spacer(),
        ],
      ),
    ),
  );
}

// 4. Alarm Indicator
Widget buildAlarmIndicator(
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
  final active = data.boolValue;
  return Card(
    color: active ? theme.colorScheme.errorContainer : null,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            active ? Icons.warning : Icons.check_circle,
            size: 36,
            color: active ? theme.colorScheme.error : Colors.green,
          ),
          const SizedBox(height: 8),
          Text(
            widget.title,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            active ? 'ACTIVE' : 'Clear',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: active ? theme.colorScheme.error : Colors.green,
            ),
          ),
        ],
      ),
    ),
  );
}

// 5. Command Status
Widget buildCommandStatus(
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
  final status = data.stringValue;
  final isSuccess =
      status.toLowerCase() == 'success' || status.toLowerCase() == 'completed';
  final isPending =
      status.toLowerCase() == 'pending' || status.toLowerCase() == 'sent';
  Color statusColor;
  IconData statusIcon;
  if (isSuccess) {
    statusColor = Colors.green;
    statusIcon = Icons.check_circle;
  } else if (isPending) {
    statusColor = Colors.orange;
    statusIcon = Icons.hourglass_bottom;
  } else {
    statusColor = theme.colorScheme.error;
    statusIcon = Icons.error;
  }
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.send, size: 18, color: theme.colorScheme.primary),
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
              Icon(statusIcon, size: 20, color: statusColor),
              const SizedBox(width: 8),
              Text(
                status,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
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

// 6. Last Seen
Widget buildLastSeen(
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
  String timeText = '--';
  if (data.hasData) {
    final ts = DateTime.tryParse(data.stringValue);
    if (ts != null) {
      final diff = DateTime.now().difference(ts);
      if (diff.inSeconds < 60) {
        timeText = '${diff.inSeconds}s ago';
      } else if (diff.inMinutes < 60) {
        timeText = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeText = '${diff.inHours}h ago';
      } else {
        timeText = '${diff.inDays}d ago';
      }
    } else {
      timeText = data.stringValue;
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
                Icons.access_time,
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
          Text(
            timeText,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
        ],
      ),
    ),
  );
}
