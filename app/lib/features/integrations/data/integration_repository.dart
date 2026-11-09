import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/integration_entity.dart';

class IntegrationRepository {
  final SupabaseClient _client;

  IntegrationRepository(this._client);

  Future<Result<List<Integration>>> getIntegrations({String? projectId}) async {
    try {
      var query = _client.from('integrations').select();
      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }
      final response = await query.order('created_at', ascending: false);
      final integrations = (response as List)
          .map((e) => Integration.fromJson(e))
          .toList();
      return Result.success(integrations);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Integration>> createIntegration({
    required String projectId,
    required String name,
    required IntegrationType integrationType,
    Map<String, dynamic> config = const {},
  }) async {
    try {
      final response = await _client
          .from('integrations')
          .insert({
            'project_id': projectId,
            'name': name,
            'integration_type': integrationType.name,
            'config': config,
            'is_enabled': true,
          })
          .select()
          .single();
      return Result.success(Integration.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> toggleIntegration(String id, bool enabled) async {
    try {
      await _client
          .from('integrations')
          .update({'is_enabled': enabled})
          .eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteIntegration(String id) async {
    try {
      await _client.from('integrations').delete().eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final integrationRepositoryProvider = Provider<IntegrationRepository>((ref) {
  return IntegrationRepository(ref.watch(supabaseClientProvider));
});
