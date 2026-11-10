enum ExecutionStatus {
  running,
  completed,
  failed,
  cancelled;

  String get displayName => switch (this) {
    running => 'Running',
    completed => 'Completed',
    failed => 'Failed',
    cancelled => 'Cancelled',
  };

  static ExecutionStatus fromString(String value) {
    return ExecutionStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ExecutionStatus.failed,
    );
  }
}

enum EventStatus {
  pending,
  processing,
  completed,
  failed,
  skipped;

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => EventStatus.pending,
    );
  }
}

class NodeResult {
  final String nodeId;
  final String nodeType;
  final String status;
  final dynamic output;
  final String? error;
  final DateTime evaluatedAt;

  const NodeResult({
    required this.nodeId,
    required this.nodeType,
    required this.status,
    this.output,
    this.error,
    required this.evaluatedAt,
  });

  Map<String, dynamic> toJson() => {
    'node_id': nodeId,
    'node_type': nodeType,
    'status': status,
    'output': output,
    'error': error,
    'evaluated_at': evaluatedAt.toIso8601String(),
  };

  factory NodeResult.fromJson(Map<String, dynamic> json) {
    return NodeResult(
      nodeId: json['node_id'] as String,
      nodeType: json['node_type'] as String,
      status: json['status'] as String,
      output: json['output'],
      error: json['error'] as String?,
      evaluatedAt: DateTime.parse(json['evaluated_at'] as String),
    );
  }
}

class RuleExecution {
  final String id;
  final String automationId;
  final String? triggerId;
  final Map<String, dynamic> triggerData;
  final ExecutionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final List<Map<String, dynamic>> actionsExecuted;
  final int? durationMs;
  final String? correlationId;
  final int executionDepth;
  final List<NodeResult> nodeResults;
  final String? ruleVersionId;
  final bool dryRun;

  const RuleExecution({
    required this.id,
    required this.automationId,
    this.triggerId,
    this.triggerData = const {},
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.actionsExecuted = const [],
    this.durationMs,
    this.correlationId,
    this.executionDepth = 0,
    this.nodeResults = const [],
    this.ruleVersionId,
    this.dryRun = false,
  });

  factory RuleExecution.fromJson(Map<String, dynamic> json) {
    return RuleExecution(
      id: json['id'] as String,
      automationId: json['automation_id'] as String,
      triggerId: json['trigger_id'] as String?,
      triggerData: Map<String, dynamic>.from(
        json['trigger_data'] as Map? ?? {},
      ),
      status: ExecutionStatus.fromString(json['status'] as String),
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      errorMessage: json['error_message'] as String?,
      actionsExecuted:
          (json['actions_executed'] as List?)?.cast<Map<String, dynamic>>() ??
          [],
      durationMs: json['duration_ms'] as int?,
      correlationId: json['correlation_id'] as String?,
      executionDepth: json['execution_depth'] as int? ?? 0,
      nodeResults:
          (json['node_results'] as List?)
              ?.map((r) => NodeResult.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      ruleVersionId: json['rule_version_id'] as String?,
      dryRun: json['dry_run'] as bool? ?? false,
    );
  }
}

class RuleEvent {
  final String id;
  final String eventType;
  final String? deviceId;
  final String projectId;
  final String organizationId;
  final Map<String, dynamic> payload;
  final String? idempotencyKey;
  final String correlationId;
  final String? causationId;
  final int depth;
  final EventStatus status;
  final DateTime? processedAt;
  final String? errorMessage;
  final DateTime createdAt;

  const RuleEvent({
    required this.id,
    required this.eventType,
    this.deviceId,
    required this.projectId,
    required this.organizationId,
    this.payload = const {},
    this.idempotencyKey,
    required this.correlationId,
    this.causationId,
    this.depth = 0,
    this.status = EventStatus.pending,
    this.processedAt,
    this.errorMessage,
    required this.createdAt,
  });

  factory RuleEvent.fromJson(Map<String, dynamic> json) {
    return RuleEvent(
      id: json['id'] as String,
      eventType: json['event_type'] as String,
      deviceId: json['device_id'] as String?,
      projectId: json['project_id'] as String,
      organizationId: json['organization_id'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      idempotencyKey: json['idempotency_key'] as String?,
      correlationId: json['correlation_id'] as String,
      causationId: json['causation_id'] as String?,
      depth: json['depth'] as int? ?? 0,
      status: EventStatus.fromString(json['status'] as String? ?? 'pending'),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
