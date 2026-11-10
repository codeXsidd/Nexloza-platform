import 'package:flutter/material.dart';

import '../../domain/entities/rule_node_type.dart';

class NodeCatalogSheet extends StatefulWidget {
  final ValueChanged<RuleNodeType> onNodeSelected;

  const NodeCatalogSheet({super.key, required this.onNodeSelected});

  @override
  State<NodeCatalogSheet> createState() => _NodeCatalogSheetState();

  static Future<RuleNodeType?> show(BuildContext context) async {
    RuleNodeType? selected;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => NodeCatalogSheet(
          onNodeSelected: (type) {
            selected = type;
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
    return selected;
  }
}

class _NodeCatalogSheetState extends State<NodeCatalogSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = RuleNodeType.values.where((t) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return t.displayName.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.category.displayName.toLowerCase().contains(q);
    }).toList();

    final grouped = <RuleNodeCategory, List<RuleNodeType>>{};
    for (final type in filtered) {
      grouped.putIfAbsent(type.category, () => []).add(type);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Icon(Icons.add_box, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Add Node', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search nodes...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              for (final category in RuleNodeCategory.values)
                if (grouped.containsKey(category)) ...[
                  _CategoryHeader(category: category),
                  for (final type in grouped[category]!)
                    _NodeTile(
                      type: type,
                      onTap: () => widget.onNodeSelected(type),
                    ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final RuleNodeCategory category;

  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(category.icon, size: 18, color: category.color),
          const SizedBox(width: 8),
          Text(
            category.displayName,
            style: theme.textTheme.labelLarge?.copyWith(
              color: category.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeTile extends StatelessWidget {
  final RuleNodeType type;
  final VoidCallback onTap;

  const _NodeTile({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Icon(type.icon, color: type.category.color, size: 22),
      title: Text(type.displayName, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        type.description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}
