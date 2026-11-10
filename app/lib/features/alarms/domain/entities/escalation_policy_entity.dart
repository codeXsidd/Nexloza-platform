class EscalationPolicy {
  final String id;
  final String projectId;
  final String organizationId;
  final String name;
  final String? description;
  final bool isEnabled;
  final List<EscalationStage> stages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EscalationPolicy({
    required this.id,
    required this.projectId,
    required this.organizationId,
    required this.name,
    this.description,
    required this.isEnabled,
    required this.stages,
    required this.createdAt,
    required this.updatedAt,
  });

  int get stageCount => stages.length;
  int get totalEscalationMinutes =>
      stages.fold(0, (sum, s) => sum + s.delayMinutes);

  factory EscalationPolicy.fromJson(Map<String, dynamic> json) {
    final stagesList = json['escalation_stages'] as List<dynamic>? ?? [];
    return EscalationPolicy(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isEnabled: json['is_enabled'] as bool? ?? true,
      stages: stagesList
          .map((s) => EscalationStage.fromJson(s as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber)),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'organization_id': organizationId,
        'name': name,
        'description': description,
        'is_enabled': isEnabled,
      };
}

class EscalationStage {
  final String id;
  final String policyId;
  final int stageNumber;
  final int delayMinutes;
  final List<String> notificationTargets;
  final String actionType;
  final DateTime createdAt;

  const EscalationStage({
    required this.id,
    required this.policyId,
    required this.stageNumber,
    required this.delayMinutes,
    required this.notificationTargets,
    required this.actionType,
    required this.createdAt,
  });

  String get actionDisplayName => switch (actionType) {
        'notify' => 'Notify',
        'reassign' => 'Reassign',
        'auto_acknowledge' => 'Auto Acknowledge',
        _ => actionType,
      };

  factory EscalationStage.fromJson(Map<String, dynamic> json) {
    final targets = json['notification_targets'];
    List<String> targetList = [];
    if (targets is List) {
      targetList = targets.map((e) => e.toString()).toList();
    }
    return EscalationStage(
      id: json['id'] as String,
      policyId: json['policy_id'] as String,
      stageNumber: json['stage_number'] as int? ?? 1,
      delayMinutes: json['delay_minutes'] as int? ?? 15,
      notificationTargets: targetList,
      actionType: json['action_type'] as String? ?? 'notify',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'policy_id': policyId,
        'stage_number': stageNumber,
        'delay_minutes': delayMinutes,
        'notification_targets': notificationTargets,
        'action_type': actionType,
      };
}
