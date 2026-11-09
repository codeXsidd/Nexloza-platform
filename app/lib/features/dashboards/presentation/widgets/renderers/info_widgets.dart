import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/entities/dashboard_widget_entity.dart';
import '../../../domain/widget_registry.dart';

// 1. Text Widget
Widget buildTextWidget(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  final text = widget.config['text'] as String? ?? widget.title;
  final fontSize = (widget.config['font_size'] as num?)?.toDouble() ?? 14;
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(fontSize: fontSize),
      ),
    ),
  );
}

// 2. Markdown Widget
Widget buildMarkdownWidget(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  final theme = Theme.of(context);
  final content = widget.config['content'] as String? ?? widget.title;
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Text(content, style: theme.textTheme.bodyMedium),
      ),
    ),
  );
}

// 3. Clock Widget
Widget buildClockWidget(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
) {
  return _ClockCard(widget: widget);
}

class _ClockCard extends StatefulWidget {
  final DashboardWidget widget;
  const _ClockCard({required this.widget});
  @override
  State<_ClockCard> createState() => _ClockCardState();
}

class _ClockCardState extends State<_ClockCard> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSeconds = widget.widget.config['show_seconds'] as bool? ?? true;
    final time = showSeconds
        ? '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}'
        : '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final date =
        '${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. Event Log
Widget buildEventLog(
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
  final events = <Map<String, dynamic>>[];
  if (data.currentValue is List) {
    for (final item in data.currentValue as List) {
      if (item is Map<String, dynamic>) {
        events.add(item);
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
              Icon(Icons.list_alt, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${events.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (events.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No events',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (_, i) {
                  final event = events[i];
                  final message = event['message'] as String? ?? '';
                  final time = event['time'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          time,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
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

// 5. Device List
Widget buildDeviceList(
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
  final devices = <Map<String, dynamic>>[];
  if (data.currentValue is List) {
    for (final item in data.currentValue as List) {
      if (item is Map<String, dynamic>) {
        devices.add(item);
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
                Icons.device_hub,
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
              Text(
                '${devices.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (devices.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No devices',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (_, i) {
                  final device = devices[i];
                  final name = device['name'] as String? ?? 'Device ${i + 1}';
                  final online = device['online'] as bool? ?? false;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: online
                                ? Colors.green
                                : theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          online ? 'Online' : 'Offline',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: online
                                ? Colors.green
                                : theme.colorScheme.outline,
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
