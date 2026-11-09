import 'package:flutter/material.dart';

import 'entities/dashboard_widget_entity.dart';
import 'entities/widget_type.dart';

class WidgetDataState {
  final dynamic currentValue;
  final bool isLoading;
  final String? error;
  final List<({DateTime time, double value})> history;
  final Map<String, dynamic> deviceInfo;
  final bool isStale;

  const WidgetDataState({
    this.currentValue,
    this.isLoading = false,
    this.error,
    this.history = const [],
    this.deviceInfo = const {},
    this.isStale = false,
  });

  double get numericValue {
    if (currentValue is num) return (currentValue as num).toDouble();
    if (currentValue is String) {
      return double.tryParse(currentValue as String) ?? 0;
    }
    return 0;
  }

  bool get boolValue {
    if (currentValue is bool) return currentValue as bool;
    if (currentValue is num) return (currentValue as num) != 0;
    if (currentValue is String) {
      return (currentValue as String).toLowerCase() == 'true' ||
          currentValue == '1';
    }
    return false;
  }

  String get stringValue => currentValue?.toString() ?? '--';

  bool get hasData => currentValue != null;
  bool get hasError => error != null;
}

typedef WidgetRendererBuilder = Widget Function(
  BuildContext context,
  DashboardWidget widget,
  WidgetDataState data,
);

typedef WidgetCommandCallback = void Function(
  String deviceId,
  String actuatorKey,
  dynamic value,
);

class WidgetRegistration {
  final NexWidgetType type;
  final WidgetRendererBuilder builder;

  const WidgetRegistration({required this.type, required this.builder});
}

class WidgetRegistry {
  static final WidgetRegistry _instance = WidgetRegistry._();
  factory WidgetRegistry() => _instance;
  WidgetRegistry._();

  final Map<NexWidgetType, WidgetRegistration> _registrations = {};

  void register(WidgetRegistration registration) {
    _registrations[registration.type] = registration;
  }

  void registerAll(List<WidgetRegistration> registrations) {
    for (final r in registrations) {
      _registrations[r.type] = r;
    }
  }

  bool isRegistered(NexWidgetType type) => _registrations.containsKey(type);

  Widget build(
    BuildContext context,
    DashboardWidget widget,
    WidgetDataState data,
  ) {
    final reg = _registrations[widget.widgetType];
    if (reg != null) {
      return reg.builder(context, widget, data);
    }
    return _UnregisteredWidget(widget: widget);
  }

  List<NexWidgetType> get registeredTypes => _registrations.keys.toList();

  List<NexWidgetType> registeredByCategory(WidgetCategory category) =>
      _registrations.keys.where((t) => t.category == category).toList();
}

class _UnregisteredWidget extends StatelessWidget {
  final DashboardWidget widget;
  const _UnregisteredWidget({required this.widget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.extension_off, color: theme.colorScheme.outline),
            const SizedBox(height: 4),
            Text(
              widget.widgetType.displayName,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
