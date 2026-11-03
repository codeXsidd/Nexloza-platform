import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nexioza/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexioza/features/projects/data/project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(supabaseClientProvider));
});

final projectsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(projectRepositoryProvider).getProjects();
});

final categoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(projectRepositoryProvider).getCategories();
});
