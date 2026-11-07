import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/project_entity.dart';

class ProjectRepository {
  final SupabaseClient _client;

  ProjectRepository(this._client);

  Future<Result<List<Project>>> getProjects() async {
    try {
      final response = await _client
          .from('projects')
          .select()
          .order('created_at', ascending: false);
      final projects = (response as List)
          .map((e) => Project.fromJson(e))
          .toList();
      return Result.success(projects);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Project>> getProject(String id) async {
    try {
      final response = await _client
          .from('projects')
          .select()
          .eq('id', id)
          .single();
      return Result.success(Project.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Project>> createProject({
    required String name,
    String? description,
    String? category,
  }) async {
    try {
      final response = await _client
          .from('projects')
          .insert({
            'name': name,
            'description': description,
            'category': category,
            'owner_id': _client.auth.currentUser!.id,
          })
          .select()
          .single();
      return Result.success(Project.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Project>> updateProject(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client
          .from('projects')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return Result.success(Project.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteProject(String id) async {
    try {
      await _client.from('projects').delete().eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(supabaseClientProvider));
});
