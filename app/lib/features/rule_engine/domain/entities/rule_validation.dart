import 'rule_graph.dart';
import 'rule_node_type.dart';

class ValidationError {
  final String? nodeId;
  final String message;

  const ValidationError({this.nodeId, required this.message});

  @override
  String toString() => nodeId != null ? '[$nodeId] $message' : message;
}

class RuleGraphValidator {
  const RuleGraphValidator();

  List<ValidationError> validate(RuleGraph graph) {
    final errors = <ValidationError>[];
    _validateTriggerCount(graph, errors);
    _validateNodeConfigs(graph, errors);
    _validateEdgeConnections(graph, errors);
    _validateDisconnectedNodes(graph, errors);
    _validateCycles(graph, errors);
    _validatePortTypes(graph, errors);
    return errors;
  }

  void _validateTriggerCount(RuleGraph graph, List<ValidationError> errors) {
    final triggers = graph.triggerNodes;
    if (triggers.isEmpty) {
      errors.add(
        const ValidationError(
          message: 'Rule must have at least one trigger node',
        ),
      );
    }
    if (triggers.length > 1) {
      for (final t in triggers.skip(1)) {
        errors.add(
          ValidationError(
            nodeId: t.id,
            message: 'Only one trigger node is allowed per rule',
          ),
        );
      }
    }
  }

  void _validateNodeConfigs(RuleGraph graph, List<ValidationError> errors) {
    for (final node in graph.nodes) {
      for (final key in node.type.requiredConfigKeys) {
        if (!node.config.containsKey(key) || node.config[key] == null) {
          errors.add(
            ValidationError(
              nodeId: node.id,
              message:
                  '${node.type.displayName}: missing required config "$key"',
            ),
          );
        }
      }

      if (node.type == RuleNodeType.greaterThan ||
          node.type == RuleNodeType.greaterThanOrEqual ||
          node.type == RuleNodeType.lessThan ||
          node.type == RuleNodeType.lessThanOrEqual ||
          node.type == RuleNodeType.equalTo ||
          node.type == RuleNodeType.notEqualTo) {
        final value = node.config['value'];
        if (value != null &&
            value is! num &&
            value is! bool &&
            value is! String) {
          errors.add(
            ValidationError(
              nodeId: node.id,
              message:
                  '${node.type.displayName}: value must be a number, boolean, or string',
            ),
          );
        }
      }

      if (node.type == RuleNodeType.betweenRange) {
        final min = node.config['min_value'];
        final max = node.config['max_value'];
        if (min is num && max is num && min > max) {
          errors.add(
            ValidationError(
              nodeId: node.id,
              message: 'Between Range: min_value must be <= max_value',
            ),
          );
        }
      }

      if (node.type == RuleNodeType.delay) {
        final duration = node.config['duration_ms'];
        if (duration is num && (duration < 100 || duration > 3600000)) {
          errors.add(
            ValidationError(
              nodeId: node.id,
              message: 'Delay: duration must be 100ms–3600000ms (1 hour)',
            ),
          );
        }
      }
    }
  }

  void _validateEdgeConnections(RuleGraph graph, List<ValidationError> errors) {
    final nodeIds = graph.nodes.map((n) => n.id).toSet();

    for (final edge in graph.edges) {
      if (!nodeIds.contains(edge.sourceNodeId)) {
        errors.add(
          ValidationError(
            message:
                'Edge ${edge.id}: source node "${edge.sourceNodeId}" not found',
          ),
        );
      }
      if (!nodeIds.contains(edge.targetNodeId)) {
        errors.add(
          ValidationError(
            message:
                'Edge ${edge.id}: target node "${edge.targetNodeId}" not found',
          ),
        );
      }

      if (edge.sourceNodeId == edge.targetNodeId) {
        errors.add(
          ValidationError(
            nodeId: edge.sourceNodeId,
            message: 'Self-referencing edge not allowed',
          ),
        );
      }

      final sourceNode = graph.findNode(edge.sourceNodeId);
      if (sourceNode != null) {
        final validPorts = sourceNode.type.outputPorts.map((p) => p.id).toSet();
        if (!validPorts.contains(edge.sourcePort)) {
          errors.add(
            ValidationError(
              nodeId: edge.sourceNodeId,
              message:
                  '${sourceNode.type.displayName}: invalid output port "${edge.sourcePort}"',
            ),
          );
        }
      }

      final targetNode = graph.findNode(edge.targetNodeId);
      if (targetNode != null) {
        final validPorts = targetNode.type.inputPorts.map((p) => p.id).toSet();
        if (!validPorts.contains(edge.targetPort)) {
          errors.add(
            ValidationError(
              nodeId: edge.targetNodeId,
              message:
                  '${targetNode.type.displayName}: invalid input port "${edge.targetPort}"',
            ),
          );
        }
      }
    }
  }

  void _validateDisconnectedNodes(
    RuleGraph graph,
    List<ValidationError> errors,
  ) {
    if (graph.nodes.length <= 1) return;

    final connectedIds = <String>{};
    for (final edge in graph.edges) {
      connectedIds.add(edge.sourceNodeId);
      connectedIds.add(edge.targetNodeId);
    }

    for (final node in graph.nodes) {
      if (!node.type.isTrigger && !connectedIds.contains(node.id)) {
        errors.add(
          ValidationError(
            nodeId: node.id,
            message:
                '${node.type.displayName}: node is not connected to any other node',
          ),
        );
      }
    }
  }

  void _validateCycles(RuleGraph graph, List<ValidationError> errors) {
    final adjacency = <String, List<String>>{};
    for (final node in graph.nodes) {
      adjacency[node.id] = [];
    }
    for (final edge in graph.edges) {
      adjacency[edge.sourceNodeId]?.add(edge.targetNodeId);
    }

    final visiting = <String>{};
    final visited = <String>{};

    bool hasCycle(String nodeId) {
      if (visiting.contains(nodeId)) return true;
      if (visited.contains(nodeId)) return false;

      visiting.add(nodeId);
      for (final neighbor in adjacency[nodeId] ?? []) {
        if (hasCycle(neighbor)) return true;
      }
      visiting.remove(nodeId);
      visited.add(nodeId);
      return false;
    }

    for (final node in graph.nodes) {
      if (!visited.contains(node.id) && hasCycle(node.id)) {
        errors.add(
          ValidationError(
            nodeId: node.id,
            message:
                'Cycle detected in graph starting from "${node.type.displayName}"',
          ),
        );
        break;
      }
    }
  }

  void _validatePortTypes(RuleGraph graph, List<ValidationError> errors) {
    for (final edge in graph.edges) {
      final sourceNode = graph.findNode(edge.sourceNodeId);
      final targetNode = graph.findNode(edge.targetNodeId);
      if (sourceNode == null || targetNode == null) continue;

      NodePortDef? sourcePort;
      for (final p in sourceNode.type.outputPorts) {
        if (p.id == edge.sourcePort) {
          sourcePort = p;
          break;
        }
      }

      NodePortDef? targetPort;
      for (final p in targetNode.type.inputPorts) {
        if (p.id == edge.targetPort) {
          targetPort = p;
          break;
        }
      }

      if (sourcePort != null &&
          targetPort != null &&
          !sourcePort.dataType.canConnectTo(targetPort.dataType)) {
        errors.add(
          ValidationError(
            nodeId: edge.targetNodeId,
            message:
                'Incompatible port types: ${sourcePort.dataType.name} → ${targetPort.dataType.name}',
          ),
        );
      }
    }
  }
}
