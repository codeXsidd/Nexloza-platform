import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/automation_entity.dart';

class AutomationRepository {
  final SupabaseClient _client;

  AutomationRepository(this._client);

  Future<Result<List<Automation>>> getAutomations({
    String? projectId,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _client.from('automations').select();
      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }
      final from = page * pageSize;
      final to = from + pageSize - 1;
      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);
      final automations = (response as List)
          .map((e) => Automation.fromJson(e))
          .toList();
      return Result.success(automations);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Automation>> createAutomation({
    required String projectId,
    required String name,
    String? description,
  }) async {
    try {
      final response = await _client
          .from('automations')
          .insert({
            'project_id': projectId,
            'name': name,
            'description': description,
            'is_enabled': true,
          })
          .select()
          .single();
      return Result.success(Automation.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> toggleAutomation(String id, bool enabled) async {
    try {
      await _client
          .from('automations')
          .update({'is_enabled': enabled})
          .eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteAutomation(String id) async {
    try {
      await _client.from('automations').delete().eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final automationRepositoryProvider = Provider<AutomationRepository>((ref) {
  return AutomationRepository(ref.watch(supabaseClientProvider));
});
