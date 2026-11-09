import 'data_source.dart';
import 'widget_type.dart';

class DashboardWidget {
  final String id;
  final String dashboardId;
  final NexWidgetType widgetType;
  final String title;
  final int gridX;
  final int gridY;
  final int gridW;
  final int gridH;
  final Map<String, dynamic> config;
  final int sortOrder;
  final bool isVisible;

  const DashboardWidget({
    required this.id,
    required this.dashboardId,
    required this.widgetType,
    required this.title,
    this.gridX = 0,
    this.gridY = 0,
    this.gridW = 1,
    this.gridH = 1,
    this.config = const {},
    this.sortOrder = 0,
    this.isVisible = true,
  });

  factory DashboardWidget.fromJson(Map<String, dynamic> json) {
    return DashboardWidget(
      id: json['id'] as String,
      dashboardId: json['dashboard_id'] as String,
      widgetType: NexWidgetType.fromTypeId(json['widget_type'] as String),
      title: json['title'] as String? ?? '',
      gridX: json['grid_x'] as int? ?? 0,
      gridY: json['grid_y'] as int? ?? 0,
      gridW: json['grid_w'] as int? ?? 1,
      gridH: json['grid_h'] as int? ?? 1,
      config: json['config'] as Map<String, dynamic>? ?? {},
      sortOrder: json['sort_order'] as int? ?? 0,
      isVisible: json['is_visible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'dashboard_id': dashboardId,
    'widget_type': widgetType.typeId,
    'title': title,
    'grid_x': gridX,
    'grid_y': gridY,
    'grid_w': gridW,
    'grid_h': gridH,
    'config': config,
    'sort_order': sortOrder,
    'is_visible': isVisible,
  };

  DataSource get dataSource {
    final ds = config['data_source'];
    if (ds is Map<String, dynamic>) {
      return DataSource.fromJson(ds);
    }
    return const DataSource();
  }

  Map<String, dynamic> get displayConfig =>
      config['display'] as Map<String, dynamic>? ?? {};

  List<Map<String, dynamic>> get thresholds {
    final t = config['thresholds'];
    if (t is List) {
      return t.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Map<String, dynamic> get chartConfig =>
      config['chart'] as Map<String, dynamic>? ?? {};

  Map<String, dynamic> get rangeConfig =>
      config['range'] as Map<String, dynamic>? ?? {};

  double get rangeMin => (rangeConfig['min'] as num?)?.toDouble() ?? 0;
  double get rangeMax => (rangeConfig['max'] as num?)?.toDouble() ?? 100;

  String get unit => displayConfig['unit'] as String? ?? '';
  int get decimals => displayConfig['decimals'] as int? ?? 1;
  String? get colorHex => displayConfig['color'] as String?;

  DashboardWidget copyWith({
    String? id,
    String? dashboardId,
    NexWidgetType? widgetType,
    String? title,
    int? gridX,
    int? gridY,
    int? gridW,
    int? gridH,
    Map<String, dynamic>? config,
    int? sortOrder,
    bool? isVisible,
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
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
