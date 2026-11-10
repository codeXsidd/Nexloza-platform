import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/rule_graph.dart';

class EdgePainter extends CustomPainter {
  final List<RuleEdge> edges;
  final Map<String, RuleNode> nodes;
  final String? selectedEdgeId;
  final Offset? pendingStart;
  final Offset? pendingEnd;
  final Color pendingColor;

  EdgePainter({
    required this.edges,
    required this.nodes,
    this.selectedEdgeId,
    this.pendingStart,
    this.pendingEnd,
    this.pendingColor = Colors.grey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final sourceNode = nodes[edge.sourceNodeId];
      final targetNode = nodes[edge.targetNodeId];
      if (sourceNode == null || targetNode == null) continue;

      final start = _outputPortPosition(sourceNode, edge.sourcePort);
      final end = _inputPortPosition(targetNode, edge.targetPort);
      final color = sourceNode.type.category.color;
      final isSelected = edge.id == selectedEdgeId;

      _drawBezier(canvas, start, end, color, isSelected: isSelected);
      _drawArrowHead(canvas, start, end, color, isSelected: isSelected);
    }

    if (pendingStart != null && pendingEnd != null) {
      _drawPendingLine(canvas, pendingStart!, pendingEnd!);
    }
  }

  void _drawBezier(Canvas canvas, Offset start, Offset end, Color color,
      {bool isSelected = false}) {
    final paint = Paint()
      ..color = isSelected ? color : color.withValues(alpha: 0.7)
      ..strokeWidth = isSelected ? 3.0 : 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dx = (end.dx - start.dx).abs() * 0.5;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + dx,
        start.dy,
        end.dx - dx,
        end.dy,
        end.dx,
        end.dy,
      );

    canvas.drawPath(path, paint);
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Color color,
      {bool isSelected = false}) {
    final dx = (end.dx - start.dx).abs() * 0.5;
    final controlX = end.dx - dx;
    final angle = math.atan2(end.dy - end.dy, end.dx - controlX);

    const arrowSize = 8.0;
    final paint = Paint()
      ..color = isSelected ? color : color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle - 0.5),
        end.dy - arrowSize * math.sin(angle - 0.5),
      )
      ..lineTo(
        end.dx - arrowSize * math.cos(angle + 0.5),
        end.dy - arrowSize * math.sin(angle + 0.5),
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawPendingLine(Canvas canvas, Offset start, Offset end) {
    final paint = Paint()
      ..color = pendingColor.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final dx = (end.dx - start.dx).abs() * 0.5;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(start.dx + dx, start.dy, end.dx - dx, end.dy, end.dx, end.dy);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final segEnd = math.min(distance + dashWidth, metric.length);
        final segment = metric.extractPath(distance, segEnd);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  static const double _nodeWidth = 180;
  static const double _headerHeight = 36;
  static const double _portSpacing = 24;

  Offset _outputPortPosition(RuleNode node, String portId) {
    final ports = node.type.outputPorts;
    int idx = 0;
    for (int i = 0; i < ports.length; i++) {
      if (ports[i].id == portId) {
        idx = i;
        break;
      }
    }
    final y = node.position.dy + _headerHeight + 12 + idx * _portSpacing;
    return Offset(node.position.dx + _nodeWidth, y);
  }

  Offset _inputPortPosition(RuleNode node, String portId) {
    final ports = node.type.inputPorts;
    int idx = 0;
    for (int i = 0; i < ports.length; i++) {
      if (ports[i].id == portId) {
        idx = i;
        break;
      }
    }
    final y = node.position.dy + _headerHeight + 12 + idx * _portSpacing;
    return Offset(node.position.dx, y);
  }

  @override
  bool shouldRepaint(covariant EdgePainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.nodes != nodes ||
        oldDelegate.selectedEdgeId != selectedEdgeId ||
        oldDelegate.pendingStart != pendingStart ||
        oldDelegate.pendingEnd != pendingEnd;
  }
}

class GridPainter extends CustomPainter {
  final double spacing;
  final Color dotColor;

  const GridPainter({
    this.spacing = 20,
    this.dotColor = const Color(0x20808080),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => false;
}
