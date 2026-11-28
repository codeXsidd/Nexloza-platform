import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/offline_sync_service.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/dashboard_entity.dart';
import '../domain/entities/dashboard_widget_entity.dart';

class DashboardRepository {
  final SupabaseClient _client;

  final OfflineSyncService? _offline;

  DashboardRepository(this._client, {OfflineSyncService? offline})
    : _offline = offline;

  Future<Result<List<Dashboard>>> getDashboards({String? projectId}) async {
    try {
      final response = await cachedRead(
        _offline,
        'dashboards',
        projectId ?? 'all',
        'list',
        () async {
          var query = _client.from('dashboards').select();
          if (projectId != null) {
            query = query.eq('project_id', projectId);
          }
          return await query
              .order('sort_order')
              .order('created_at', ascending: false);
        },
      );
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

  Future<Result<Dashboard>> getDashboard(String id) async {
    try {
      final response = await cachedRead(
        _offline,
        'dashboards',
        id,
        'detail',
        () async =>
            await _client.from('dashboards').select().eq('id', id).single(),
      );
      return Result.success(
        Dashboard.fromJson(response as Map<String, dynamic>),
      );
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
    Map<String, dynamic>? layout,
  }) async {
    try {
      final data = <String, dynamic>{
        'project_id': projectId,
        'name': name,
        'description': description,
      };
      if (layout != null) {
        data['layout'] = layout;
      }
      final response = await _client
          .from('dashboards')
          .insert(data)
          .select()
          .single();
      return Result.success(Dashboard.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> updateDashboard(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client.from('dashboards').update(updates).eq('id', id);
      return Result.success(null);
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

  Future<Result<Dashboard>> duplicateDashboard(
    String id, {
    String? newName,
  }) async {
    try {
      final original = await _client
          .from('dashboards')
          .select()
          .eq('id', id)
          .single();
      final widgets = await _client
          .from('dashboard_widgets')
          .select()
          .eq('dashboard_id', id);

      final newDashboard = await _client
          .from('dashboards')
          .insert({
            'project_id': original['project_id'],
            'name': newName ?? '${original['name']} (Copy)',
            'description': original['description'],
            'layout': original['layout'],
          })
          .select()
          .single();

      final newId = newDashboard['id'];
      for (final w in (widgets as List)) {
        await _client.from('dashboard_widgets').insert({
          'dashboard_id': newId,
          'widget_type': w['widget_type'],
          'title': w['title'],
          'config': w['config'],
          'sort_order': w['sort_order'],
          'is_visible': w['is_visible'] ?? true,
        });
      }

      return Result.success(Dashboard.fromJson(newDashboard));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<DashboardWidget>>> getWidgets(String dashboardId) async {
    try {
      final response = await cachedRead(
        _offline,
        'dashboards',
        dashboardId,
        'widgets',
        () async => await _client
            .from('dashboard_widgets')
            .select()
            .eq('dashboard_id', dashboardId)
            .order('sort_order'),
      );
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
    required String widgetType,
    required String title,
    Map<String, dynamic> config = const {},
    int gridW = 1,
    int gridH = 1,
    int sortOrder = 0,
  }) async {
    try {
      final response = await _client
          .from('dashboard_widgets')
          .insert({
            'dashboard_id': dashboardId,
            'widget_type': widgetType,
            'title': title,
            'config': config,
            'grid_w': gridW,
            'grid_h': gridH,
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

  Future<Result<void>> reorderWidgets(
    String dashboardId,
    List<String> widgetIds,
  ) async {
    try {
      for (int i = 0; i < widgetIds.length; i++) {
        await _client
            .from('dashboard_widgets')
            .update({'sort_order': i})
            .eq('id', widgetIds[i]);
      }
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  String exportDashboardJson(
    Dashboard dashboard,
    List<DashboardWidget> widgets,
  ) {
    return jsonEncode({
      'version': 1,
      'format': 'nexloza_dashboard',
      'dashboard': {
        'name': dashboard.name,
        'description': dashboard.description,
        'layout': dashboard.layout,
        'variables': dashboard.variables,
      },
      'widgets': widgets
          .map(
            (w) => {
              'widget_type': w.widgetType.typeId,
              'title': w.title,
              'grid_x': w.gridX,
              'grid_y': w.gridY,
              'grid_w': w.gridW,
              'grid_h': w.gridH,
              'config': w.config,
              'sort_order': w.sortOrder,
            },
          )
          .toList(),
      'exported_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Result<Dashboard>> importDashboardJson(
    String projectId,
    String jsonStr,
  ) async {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (data['format'] != 'nexloza_dashboard') {
        return Result.failure(
          const ValidationFailure('Invalid dashboard format'),
        );
      }

      final dashData = data['dashboard'] as Map<String, dynamic>;
      final widgetsData = data['widgets'] as List;

      final dashResult = await createDashboard(
        projectId: projectId,
        name: dashData['name'] as String? ?? 'Imported Dashboard',
        description: dashData['description'] as String?,
        layout: dashData['layout'] as Map<String, dynamic>?,
      );

      return await dashResult.when(
        success: (dashboard) async {
          for (final w in widgetsData) {
            final wMap = w as Map<String, dynamic>;
            await addWidget(
              dashboardId: dashboard.id,
              widgetType: wMap['widget_type'] as String? ?? 'text_widget',
              title: wMap['title'] as String? ?? '',
              config: wMap['config'] as Map<String, dynamic>? ?? {},
              gridW: wMap['grid_w'] as int? ?? 1,
              gridH: wMap['grid_h'] as int? ?? 1,
              sortOrder: wMap['sort_order'] as int? ?? 0,
            );
          }
          return Result.success(dashboard);
        },
        failure: (f) => Result.failure(f),
      );
    } on FormatException {
      return Result.failure(const ValidationFailure('Invalid JSON'));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    ref.watch(supabaseClientProvider),
    offline: ref.watch(offlineSyncProvider),
  );
});
