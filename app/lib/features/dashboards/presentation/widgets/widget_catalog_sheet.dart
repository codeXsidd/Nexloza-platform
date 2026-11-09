import 'package:flutter/material.dart';

import '../../domain/entities/widget_type.dart';

class WidgetCatalogSheet extends StatefulWidget {
  final void Function(NexWidgetType type) onSelect;

  const WidgetCatalogSheet({super.key, required this.onSelect});

  @override
  State<WidgetCatalogSheet> createState() => _WidgetCatalogSheetState();
}

class _WidgetCatalogSheetState extends State<WidgetCatalogSheet> {
  WidgetCategory? _selectedCategory;
  String _search = '';

  List<NexWidgetType> get _filteredTypes {
    var types = NexWidgetType.values.toList();
    if (_selectedCategory != null) {
      types = types.where((t) => t.category == _selectedCategory).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      types = types
          .where(
            (t) =>
                t.displayName.toLowerCase().contains(q) || t.typeId.contains(q),
          )
          .toList();
    }
    return types;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final types = _filteredTypes;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.widgets, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Add Widget', style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search widgets...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  for (final cat in WidgetCategory.values)
                    _CategoryChip(
                      label: cat.displayName,
                      icon: cat.icon,
                      selected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: types.isEmpty
                  ? Center(
                      child: Text(
                        'No widgets found',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: types.length,
                      itemBuilder: (context, index) {
                        final type = types[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              type.icon,
                              size: 20,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(type.displayName),
                          subtitle: Text(type.category.displayName),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () {
                            widget.onSelect(type);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
