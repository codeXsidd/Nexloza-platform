import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../data/project_repository.dart';
import '../../domain/entities/project_entity.dart';

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    ref.watch(currentUserProvider);
    final repo = ref.read(projectRepositoryProvider);
    final result = await repo.getProjects();
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<bool> createProject({
    required String name,
    String? description,
    String? category,
  }) async {
    final repo = ref.read(projectRepositoryProvider);
    final result = await repo.createProject(
      name: name,
      description: description,
      category: category,
    );
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> updateProject(String id, Map<String, dynamic> updates) async {
    final repo = ref.read(projectRepositoryProvider);
    final result = await repo.updateProject(id, updates);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> deleteProject(String id) async {
    final repo = ref.read(projectRepositoryProvider);
    final result = await repo.deleteProject(id);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }
}

final projectsProvider = AsyncNotifierProvider<ProjectsNotifier, List<Project>>(
  ProjectsNotifier.new,
);

final projectDetailProvider = FutureProvider.family<Project?, String>((
  ref,
  id,
) async {
  ref.watch(currentUserProvider);
  final repo = ref.watch(projectRepositoryProvider);
  final result = await repo.getProject(id);
  return result.when(success: (p) => p, failure: (_) => null);
});
