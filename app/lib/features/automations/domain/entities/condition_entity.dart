enum ConditionType {
  valueComparison,
  timeWindow,
  deviceStatus,
  compoundAnd,
  compoundOr;

  String get displayName => switch (this) {
        valueComparison => 'Value Comparison',
        timeWindow => 'Time Window',
        deviceStatus => 'Device Status',
        compoundAnd => 'All conditions (AND)',
        compoundOr => 'Any condition (OR)',
      };
}

class AutomationCondition {
  final String id;
  final String automationId;
  final ConditionType conditionType;
  final Map<String, dynamic> config;
  final int sortOrder;

  const AutomationCondition({
    required this.id,
    required this.automationId,
    required this.conditionType,
    required this.config,
    this.sortOrder = 0,
  });

  factory AutomationCondition.fromJson(Map<String, dynamic> json) {
    return AutomationCondition(
      id: json['id'] as String,
      automationId: json['automation_id'] as String,
      conditionType: ConditionType.values.firstWhere(
        (c) => c.name == json['condition_type'],
        orElse: () => ConditionType.valueComparison,
      ),
      config: json['config'] as Map<String, dynamic>? ?? {},
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
