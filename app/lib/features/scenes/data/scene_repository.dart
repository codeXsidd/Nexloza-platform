import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/scene_entity.dart';

class SceneRepository {
  final SupabaseClient _client;

  SceneRepository(this._client);

  Future<Result<List<Scene>>> getScenes({String? projectId}) async {
    try {
      var query = _client.from('scenes').select();
      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }
      final response = await query.order('created_at', ascending: false);
      final scenes = (response as List).map((e) => Scene.fromJson(e)).toList();
      return Result.success(scenes);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Scene>> createScene({
    required String projectId,
    required String name,
    String? description,
    String? icon,
  }) async {
    try {
      final response = await _client
          .from('scenes')
          .insert({
            'project_id': projectId,
            'name': name,
            'description': description,
            'icon': icon,
            'is_active': true,
          })
          .select()
          .single();
      return Result.success(Scene.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> toggleScene(String id, bool active) async {
    try {
      await _client.from('scenes').update({'is_active': active}).eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> activateScene(String id) async {
    try {
      await _client.functions.invoke(
        'automation-engine',
        body: {'action': 'activate_scene', 'scene_id': id},
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteScene(String id) async {
    try {
      await _client.from('scenes').delete().eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final sceneRepositoryProvider = Provider<SceneRepository>((ref) {
  return SceneRepository(ref.watch(supabaseClientProvider));
});
