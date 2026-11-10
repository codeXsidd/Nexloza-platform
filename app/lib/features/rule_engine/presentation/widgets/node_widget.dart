import 'package:flutter/material.dart';

import '../../domain/entities/rule_graph.dart';

class NodeWidget extends StatelessWidget {
  final RuleNode node;
  final bool isSelected;
  final bool hasError;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onMoved;
  final VoidCallback? onDelete;
  final void Function(String nodeId, String portId, bool isOutput)?
      onPortTapDown;
  final void Function(String nodeId, String portId, bool isOutput)? onPortTapUp;

  static const double width = 180;
  static const double headerHeight = 36;
  static const double portSpacing = 24;
  static const double portRadius = 6;

  const NodeWidget({
    super.key,
    required this.node,
    this.isSelected = false,
    this.hasError = false,
    this.onTap,
    this.onMoved,
    this.onDelete,
    this.onPortTapDown,
    this.onPortTapUp,
  });

  double get _bodyHeight {
    final maxPorts = node.type.inputPorts.length > node.type.outputPorts.length
        ? node.type.inputPorts.length
        : node.type.outputPorts.length;
    return maxPorts > 0 ? maxPorts * portSpacing + 8 : 32;
  }

  double get totalHeight => headerHeight + _bodyHeight;

  @override
  Widget build(BuildContext context) {
    final catColor = node.type.category.color;
    final borderColor = hasError
        ? Colors.red
        : isSelected
            ? catColor
            : Colors.transparent;
    final borderWidth = (isSelected || hasError) ? 2.5 : 1.0;

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: onMoved != null
          ? (d) => onMoved!(d.delta)
          : null,
      child: SizedBox(
        width: width,
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.08),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(node: node, catColor: catColor, hasError: hasError),
                  Expanded(
                    child: _Body(node: node),
                  ),
                ],
              ),
            ),
            // Input ports (left side)
            for (int i = 0; i < node.type.inputPorts.length; i++)
              Positioned(
                left: -portRadius,
                top: headerHeight + 12 + i * portSpacing - portRadius,
                child: _PortCircle(
                  color: catColor,
                  isOutput: false,
                  onTapDown: () => onPortTapDown?.call(
                      node.id, node.type.inputPorts[i].id, false),
                  onTapUp: () => onPortTapUp?.call(
                      node.id, node.type.inputPorts[i].id, false),
                ),
              ),
            // Output ports (right side)
            for (int i = 0; i < node.type.outputPorts.length; i++)
              Positioned(
                right: -portRadius,
                top: headerHeight + 12 + i * portSpacing - portRadius,
                child: _PortCircle(
                  color: catColor,
                  isOutput: true,
                  onTapDown: () => onPortTapDown?.call(
                      node.id, node.type.outputPorts[i].id, true),
                  onTapUp: () => onPortTapUp?.call(
                      node.id, node.type.outputPorts[i].id, true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final RuleNode node;
  final Color catColor;
  final bool hasError;

  const _Header({
    required this.node,
    required this.catColor,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: NodeWidget.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: catColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        children: [
          Icon(node.type.icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              node.label.isNotEmpty ? node.label : node.type.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasError)
            const Icon(Icons.error, size: 14, color: Colors.yellowAccent),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final RuleNode node;

  const _Body({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputPorts = node.type.inputPorts;
    final outputPorts = node.type.outputPorts;
    final maxPorts =
        inputPorts.length > outputPorts.length ? inputPorts.length : outputPorts.length;

    if (maxPorts == 0) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          node.type.category.displayName,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < maxPorts; i++)
            SizedBox(
              height: NodeWidget.portSpacing,
              child: Row(
                children: [
                  if (i < inputPorts.length)
                    Expanded(
                      child: Text(
                        inputPorts[i].label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (i < outputPorts.length)
                    Expanded(
                      child: Text(
                        outputPorts[i].label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    )
                  else
                    const Spacer(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PortCircle extends StatelessWidget {
  final Color color;
  final bool isOutput;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;

  const _PortCircle({
    required this.color,
    required this.isOutput,
    this.onTapDown,
    this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown?.call(),
      onTapUp: (_) => onTapUp?.call(),
      child: Container(
        width: NodeWidget.portRadius * 2,
        height: NodeWidget.portRadius * 2,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}
