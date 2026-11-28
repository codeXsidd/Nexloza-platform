import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/offline_sync_service.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/project_entity.dart';

class ProjectRepository {
  final SupabaseClient _client;

  final OfflineSyncService? _offline;

  ProjectRepository(this._client, {OfflineSyncService? offline})
    : _offline = offline;

  Future<Result<List<Project>>> getProjects({
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;
      final response = await cachedRead(
        _offline,
        'projects',
        'all',
        'page:$page:$pageSize',
        () async => await _client
            .from('projects')
            .select()
            .order('created_at', ascending: false)
            .range(from, to),
      );
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
      final response = await cachedRead(
        _offline,
        'projects',
        id,
        'detail',
        () async =>
            await _client.from('projects').select().eq('id', id).single(),
      );
      return Result.success(Project.fromJson(response as Map<String, dynamic>));
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
    final offline = _offline;
    final account = offline?.account;
    try {
      final response = await _client
          .from('projects')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      await offline?.invalidate(account, 'projects');
      return Result.success(Project.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      if (offline != null &&
          account != null &&
          OfflineSyncService.isTransportError(e)) {
        final original = await getProject(id);
        if (offline.account == account && original is Success<Project>) {
          final project = original.data;
          try {
            await offline.queueProjectEdit(
              account: account,
              projectId: id,
              expectedVersion: project.updatedAt.toUtc().toIso8601String(),
              changes: updates,
            );
            return Result.success(project);
          } catch (_) {
            return Result.failure(
              ServerFailure('Project edit could not be queued'),
            );
          }
        }
      }
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
  return ProjectRepository(
    ref.watch(supabaseClientProvider),
    offline: ref.watch(offlineSyncProvider),
  );
});
