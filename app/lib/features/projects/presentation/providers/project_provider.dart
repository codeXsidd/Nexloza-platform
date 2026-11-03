import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexioza/core/models/project.dart';
import 'package:nexioza/core/models/project_category.dart';
import 'package:nexioza/core/models/project_member.dart';
import 'package:nexioza/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexioza/features/projects/data/project_repository.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(supabaseClientProvider));
});

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(projectRepositoryProvider).getProjects();
});

final projectProvider = FutureProvider.family<Project?, String>((
  ref,
  projectId,
) async {
  return ref.read(projectRepositoryProvider).getProject(projectId);
});

final templatesProvider = FutureProvider<List<Project>>((ref) async {
  return ref.read(projectRepositoryProvider).getTemplates();
});

final categoriesProvider = FutureProvider<List<ProjectCategory>>((ref) async {
  return ref.read(projectRepositoryProvider).getCategories();
});

final projectMembersProvider =
    FutureProvider.family<List<ProjectMember>, String>((ref, projectId) async {
      return ref.read(projectRepositoryProvider).getProjectMembers(projectId);
    });
