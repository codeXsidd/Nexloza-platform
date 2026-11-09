enum DashboardWidgetType {
  gauge,
  lineChart,
  valueDisplay,
  toggle,
  statusIndicator,
  barChart,
  map;

  String get displayName => switch (this) {
    gauge => 'Gauge',
    lineChart => 'Line Chart',
    valueDisplay => 'Value Display',
    toggle => 'Toggle Control',
    statusIndicator => 'Status Indicator',
    barChart => 'Bar Chart',
    map => 'Map',
  };

  String get icon => switch (this) {
    gauge => 'speed',
    lineChart => 'show_chart',
    valueDisplay => 'numbers',
    toggle => 'toggle_on',
    statusIndicator => 'circle',
    barChart => 'bar_chart',
    map => 'map',
  };
}

class DashboardWidget {
  final String id;
  final String dashboardId;
  final DashboardWidgetType widgetType;
  final String title;
  final int gridX;
  final int gridY;
  final int gridW;
  final int gridH;
  final Map<String, dynamic> config;
  final int sortOrder;

  const DashboardWidget({
    required this.id,
    required this.dashboardId,
    required this.widgetType,
    required this.title,
    this.gridX = 0,
    this.gridY = 0,
    this.gridW = 2,
    this.gridH = 2,
    this.config = const {},
    this.sortOrder = 0,
  });

  factory DashboardWidget.fromJson(Map<String, dynamic> json) {
    return DashboardWidget(
      id: json['id'] as String,
      dashboardId: json['dashboard_id'] as String,
      widgetType: DashboardWidgetType.values.firstWhere(
        (t) => t.name == json['widget_type'],
        orElse: () => DashboardWidgetType.valueDisplay,
      ),
      title: json['title'] as String,
      gridX: json['grid_x'] as int? ?? 0,
      gridY: json['grid_y'] as int? ?? 0,
      gridW: json['grid_w'] as int? ?? 2,
      gridH: json['grid_h'] as int? ?? 2,
      config: json['config'] as Map<String, dynamic>? ?? {},
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'dashboard_id': dashboardId,
    'widget_type': widgetType.name,
    'title': title,
    'grid_x': gridX,
    'grid_y': gridY,
    'grid_w': gridW,
    'grid_h': gridH,
    'config': config,
    'sort_order': sortOrder,
  };

  DashboardWidget copyWith({
    String? id,
    String? dashboardId,
    DashboardWidgetType? widgetType,
    String? title,
    int? gridX,
    int? gridY,
    int? gridW,
    int? gridH,
    Map<String, dynamic>? config,
    int? sortOrder,
  }) {
    return DashboardWidget(
      id: id ?? this.id,
      dashboardId: dashboardId ?? this.dashboardId,
      widgetType: widgetType ?? this.widgetType,
      title: title ?? this.title,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      gridW: gridW ?? this.gridW,
      gridH: gridH ?? this.gridH,
      config: config ?? this.config,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
