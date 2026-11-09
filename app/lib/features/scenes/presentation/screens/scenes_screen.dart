import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../theme/app_spacing.dart';
import '../../domain/entities/scene_entity.dart';
import '../providers/scene_provider.dart';

class ScenesScreen extends ConsumerWidget {
  const ScenesScreen({super.key});

  static const _sceneIcons = <String, IconData>{
    'night': Icons.nightlight_round,
    'away': Icons.flight_takeoff,
    'morning': Icons.wb_sunny,
    'security': Icons.security,
    'energy': Icons.bolt,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenesAsync = ref.watch(scenesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scenes')),
      body: scenesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              AppSpacing.verticalSm,
              Text(
                'Failed to load scenes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppSpacing.verticalSm,
              FilledButton(
                onPressed: () => ref.invalidate(scenesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (scenes) {
          if (scenes.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.theater_comedy_outlined,
              title: 'No Scenes',
              subtitle:
                  'Create scenes to activate multiple device actions at once.',
              actionLabel: 'Create Scene',
              onAction: () => context.pushNamed(RouteNames.createScene),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(scenesProvider),
            child: ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: scenes.length,
              separatorBuilder: (_, __) => AppSpacing.verticalSm,
              itemBuilder: (context, index) => _SceneCard(
                scene: scenes[index],
                icon: _iconForScene(scenes[index]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.createScene),
        icon: const Icon(Icons.add),
        label: const Text('New Scene'),
      ),
    );
  }

  IconData _iconForScene(Scene scene) {
    final lower = (scene.icon ?? scene.name).toLowerCase();
    for (final entry in _sceneIcons.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.theater_comedy;
  }
}

class _SceneCard extends ConsumerWidget {
  final Scene scene;
  final IconData icon;

  const _SceneCard({required this.scene, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scene.isActive
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: scene.isActive
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.outline,
              ),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scene.name, style: theme.textTheme.titleMedium),
                  if (scene.description != null &&
                      scene.description!.isNotEmpty)
                    Text(
                      scene.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () async {
                final success = await ref
                    .read(scenesProvider.notifier)
                    .activateScene(scene.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? '${scene.name} activated'
                            : 'Failed to activate',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Activate'),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'toggle') {
                  ref
                      .read(scenesProvider.notifier)
                      .toggleScene(scene.id, !scene.isActive);
                } else if (value == 'delete') {
                  final confirmed = await showConfirmationDialog(
                    context,
                    title: 'Delete Scene',
                    message: 'Delete "${scene.name}"?',
                    confirmLabel: 'Delete',
                    isDestructive: true,
                  );
                  if (confirmed) {
                    ref.read(scenesProvider.notifier).deleteScene(scene.id);
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(scene.isActive ? 'Disable' : 'Enable'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
