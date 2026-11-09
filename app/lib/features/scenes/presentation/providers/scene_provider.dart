import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/scene_repository.dart';
import '../../domain/entities/scene_entity.dart';

class ScenesNotifier extends AsyncNotifier<List<Scene>> {
  @override
  Future<List<Scene>> build() async {
    final repo = ref.read(sceneRepositoryProvider);
    final result = await repo.getScenes();
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<bool> createScene({
    required String projectId,
    required String name,
    String? description,
    String? icon,
  }) async {
    final repo = ref.read(sceneRepositoryProvider);
    final result = await repo.createScene(
      projectId: projectId,
      name: name,
      description: description,
      icon: icon,
    );
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> toggleScene(String id, bool active) async {
    final repo = ref.read(sceneRepositoryProvider);
    final result = await repo.toggleScene(id, active);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> activateScene(String id) async {
    final repo = ref.read(sceneRepositoryProvider);
    final result = await repo.activateScene(id);
    return result.when(success: (_) => true, failure: (_) => false);
  }

  Future<bool> deleteScene(String id) async {
    final repo = ref.read(sceneRepositoryProvider);
    final result = await repo.deleteScene(id);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }
}

final scenesProvider = AsyncNotifierProvider<ScenesNotifier, List<Scene>>(
  ScenesNotifier.new,
);
