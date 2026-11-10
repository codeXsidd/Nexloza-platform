import 'dart:ui';

import 'rule_node_type.dart';

const int currentGraphSchemaVersion = 1;

class RuleNode {
  final String id;
  final RuleNodeType type;
  final Offset position;
  final Map<String, dynamic> config;
  final String label;

  const RuleNode({
    required this.id,
    required this.type,
    required this.position,
    this.config = const {},
    this.label = '',
  });

  RuleNode copyWith({
    Offset? position,
    Map<String, dynamic>? config,
    String? label,
  }) {
    return RuleNode(
      id: id,
      type: type,
      position: position ?? this.position,
      config: config ?? this.config,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.dbValue,
    'position': {'x': position.dx, 'y': position.dy},
    'config': config,
    'label': label,
  };

  factory RuleNode.fromJson(Map<String, dynamic> json) {
    final pos = json['position'] as Map<String, dynamic>? ?? {};
    return RuleNode(
      id: json['id'] as String,
      type: RuleNodeType.fromString(json['type'] as String),
      position: Offset(
        (pos['x'] as num?)?.toDouble() ?? 0,
        (pos['y'] as num?)?.toDouble() ?? 0,
      ),
      config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
      label: json['label'] as String? ?? '',
    );
  }
}

class RuleEdge {
  final String id;
  final String sourceNodeId;
  final String sourcePort;
  final String targetNodeId;
  final String targetPort;

  const RuleEdge({
    required this.id,
    required this.sourceNodeId,
    required this.sourcePort,
    required this.targetNodeId,
    required this.targetPort,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'source_node_id': sourceNodeId,
    'source_port': sourcePort,
    'target_node_id': targetNodeId,
    'target_port': targetPort,
  };

  factory RuleEdge.fromJson(Map<String, dynamic> json) {
    return RuleEdge(
      id: json['id'] as String,
      sourceNodeId: json['source_node_id'] as String,
      sourcePort: json['source_port'] as String,
      targetNodeId: json['target_node_id'] as String,
      targetPort: json['target_port'] as String,
    );
  }
}

class RuleGraph {
  final int schemaVersion;
  final List<RuleNode> nodes;
  final List<RuleEdge> edges;

  const RuleGraph({
    this.schemaVersion = currentGraphSchemaVersion,
    this.nodes = const [],
    this.edges = const [],
  });

  RuleGraph copyWith({List<RuleNode>? nodes, List<RuleEdge>? edges}) {
    return RuleGraph(
      schemaVersion: schemaVersion,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }

  RuleNode? findNode(String nodeId) {
    for (final n in nodes) {
      if (n.id == nodeId) return n;
    }
    return null;
  }

  List<RuleEdge> edgesFrom(String nodeId) {
    return edges.where((e) => e.sourceNodeId == nodeId).toList();
  }

  List<RuleEdge> edgesTo(String nodeId) {
    return edges.where((e) => e.targetNodeId == nodeId).toList();
  }

  List<RuleNode> get triggerNodes =>
      nodes.where((n) => n.type.isTrigger).toList();

  Map<String, dynamic> toJson() => {
    'schema_version': schemaVersion,
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
  };

  factory RuleGraph.fromJson(Map<String, dynamic> json) {
    return RuleGraph(
      schemaVersion:
          json['schema_version'] as int? ?? currentGraphSchemaVersion,
      nodes:
          (json['nodes'] as List?)
              ?.map((n) => RuleNode.fromJson(n as Map<String, dynamic>))
              .toList() ??
          [],
      edges:
          (json['edges'] as List?)
              ?.map((e) => RuleEdge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static const empty = RuleGraph();
}

enum RuleStatus {
  draft,
  validated,
  published,
  enabled,
  disabled,
  archived;

  String get displayName => switch (this) {
    draft => 'Draft',
    validated => 'Validated',
    published => 'Published',
    enabled => 'Enabled',
    disabled => 'Disabled',
    archived => 'Archived',
  };

  bool get isEditable => this == draft || this == validated;
  bool get isActive => this == enabled;
  bool get canPublish => this == validated;
  bool get canEnable => this == published || this == disabled;

  static RuleStatus fromString(String value) {
    return RuleStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => RuleStatus.draft,
    );
  }
}

class RuleVersion {
  final String id;
  final String automationId;
  final int versionNumber;
  final RuleGraph graphSnapshot;
  final DateTime publishedAt;
  final String? publishedBy;

  const RuleVersion({
    required this.id,
    required this.automationId,
    required this.versionNumber,
    required this.graphSnapshot,
    required this.publishedAt,
    this.publishedBy,
  });

  factory RuleVersion.fromJson(Map<String, dynamic> json) {
    return RuleVersion(
      id: json['id'] as String,
      automationId: json['automation_id'] as String,
      versionNumber: json['version_number'] as int,
      graphSnapshot: RuleGraph.fromJson(
        json['graph_snapshot'] as Map<String, dynamic>? ?? {},
      ),
      publishedAt: DateTime.parse(json['published_at'] as String),
      publishedBy: json['published_by'] as String?,
    );
  }
}
