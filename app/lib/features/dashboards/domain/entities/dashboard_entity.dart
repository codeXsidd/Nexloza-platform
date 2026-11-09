class Dashboard {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final Map<String, dynamic> layout;
  final bool isDefault;
  final int sortOrder;
  final bool isArchived;
  final Map<String, dynamic> variables;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Dashboard({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    this.layout = const {'columns': 2, 'row_height': 80},
    this.isDefault = false,
    this.sortOrder = 0,
    this.isArchived = false,
    this.variables = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      layout:
          json['layout'] as Map<String, dynamic>? ??
          const {'columns': 2, 'row_height': 80},
      isDefault: json['is_default'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      variables: json['variables'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'project_id': projectId,
    'name': name,
    'description': description,
    'layout': layout,
    'is_default': isDefault,
    'sort_order': sortOrder,
    'variables': variables,
  };

  int get columns => (layout['columns'] as int?) ?? 2;

  Dashboard copyWith({
    String? name,
    String? description,
    Map<String, dynamic>? layout,
    bool? isDefault,
    int? sortOrder,
    bool? isArchived,
    Map<String, dynamic>? variables,
  }) {
    return Dashboard(
      id: id,
      projectId: projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      layout: layout ?? this.layout,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      variables: variables ?? this.variables,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static const List<DashboardTemplate> templates = [
    DashboardTemplate(
      name: 'Smart Home',
      description: 'Temperature, humidity, light controls, device status',
      icon: 'home',
      category: 'smart_home',
    ),
    DashboardTemplate(
      name: 'Smart Agriculture',
      description: 'Soil moisture, temperature, irrigation controls',
      icon: 'grass',
      category: 'smart_agriculture',
    ),
    DashboardTemplate(
      name: 'Smart Irrigation',
      description: 'Valve controls, soil sensors, water flow monitoring',
      icon: 'water_drop',
      category: 'smart_irrigation',
    ),
    DashboardTemplate(
      name: 'Weather Station',
      description: 'Temperature, humidity, pressure, wind, rain charts',
      icon: 'cloud',
      category: 'weather_station',
    ),
    DashboardTemplate(
      name: 'Water Monitoring',
      description: 'Tank levels, flow rates, quality metrics',
      icon: 'waves',
      category: 'water_monitoring',
    ),
    DashboardTemplate(
      name: 'Energy Monitoring',
      description: 'Voltage, current, power, energy consumption charts',
      icon: 'bolt',
      category: 'energy_monitoring',
    ),
    DashboardTemplate(
      name: 'Industrial IoT',
      description: 'Machine status, production counters, alarm panel',
      icon: 'factory',
      category: 'industrial_iot',
    ),
    DashboardTemplate(
      name: 'Machine Monitoring',
      description: 'Motor status, vibration, temperature, equipment health',
      icon: 'precision_manufacturing',
      category: 'machine_monitoring',
    ),
    DashboardTemplate(
      name: 'Smart Security',
      description: 'Motion sensors, door status, alarm indicators',
      icon: 'shield',
      category: 'smart_security',
    ),
    DashboardTemplate(
      name: 'Custom Dashboard',
      description: 'Start with a blank canvas and add any widgets',
      icon: 'dashboard_customize',
      category: 'custom',
    ),
  ];
}

class DashboardTemplate {
  final String name;
  final String description;
  final String icon;
  final String category;

  const DashboardTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
  });
}
