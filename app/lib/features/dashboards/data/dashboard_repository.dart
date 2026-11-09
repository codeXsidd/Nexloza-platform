import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/dashboard_entity.dart';
import '../domain/entities/dashboard_widget_entity.dart';

class DashboardRepository {
  final SupabaseClient _client;

  DashboardRepository(this._client);

  Future<Result<List<Dashboard>>> getDashboards({String? projectId}) async {
    try {
      var query = _client.from('dashboards').select();
      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }
      final response = await query.order('created_at', ascending: false);
      final dashboards = (response as List)
          .map((e) => Dashboard.fromJson(e))
          .toList();
      return Result.success(dashboards);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<Dashboard>> createDashboard({
    required String projectId,
    required String name,
    String? description,
  }) async {
    try {
      final response = await _client
          .from('dashboards')
          .insert({
            'project_id': projectId,
            'name': name,
            'description': description,
          })
          .select()
          .single();
      return Result.success(Dashboard.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteDashboard(String id) async {
    try {
      await _client.from('dashboards').delete().eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<DashboardWidget>>> getWidgets(String dashboardId) async {
    try {
      final response = await _client
          .from('dashboard_widgets')
          .select()
          .eq('dashboard_id', dashboardId)
          .order('sort_order');
      final widgets = (response as List)
          .map((e) => DashboardWidget.fromJson(e))
          .toList();
      return Result.success(widgets);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<DashboardWidget>> addWidget({
    required String dashboardId,
    required DashboardWidgetType widgetType,
    required String title,
    Map<String, dynamic> config = const {},
    int sortOrder = 0,
  }) async {
    try {
      final response = await _client
          .from('dashboard_widgets')
          .insert({
            'dashboard_id': dashboardId,
            'widget_type': widgetType.name,
            'title': title,
            'config': config,
            'sort_order': sortOrder,
          })
          .select()
          .single();
      return Result.success(DashboardWidget.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> updateWidget(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client.from('dashboard_widgets').update(updates).eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteWidget(String id) async {
    try {
      await _client.from('dashboard_widgets').delete().eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(supabaseClientProvider));
});
