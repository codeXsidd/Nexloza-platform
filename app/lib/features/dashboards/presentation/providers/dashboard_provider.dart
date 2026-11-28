import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/offline_sync_service.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/entities/dashboard_widget_entity.dart';

class DashboardsNotifier extends AsyncNotifier<List<Dashboard>> {
  @override
  Future<List<Dashboard>> build() async {
    ref.watch(offlineAccountProvider);
    final repo = ref.read(dashboardRepositoryProvider);
    final result = await repo.getDashboards();
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<List<Dashboard>> getForProject(String projectId) async {
    final repo = ref.read(dashboardRepositoryProvider);
    final result = await repo.getDashboards(projectId: projectId);
    return result.when(success: (data) => data, failure: (_) => []);
  }

  Future<Dashboard?> createDashboard({
    required String projectId,
    required String name,
    String? description,
    Map<String, dynamic>? layout,
  }) async {
    final repo = ref.read(dashboardRepositoryProvider);
    final result = await repo.createDashboard(
      projectId: projectId,
      name: name,
      description: description,
      layout: layout,
    );
    return result.when(
      success: (dashboard) {
        ref.invalidateSelf();
        return dashboard;
      },
      failure: (_) => null,
    );
  }

  Future<bool> updateDashboard(String id, Map<String, dynamic> updates) async {
    final repo = ref.read(dashboardRepositoryProvider);
    final result = await repo.updateDashboard(id, updates);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> deleteDashboard(String id) async {
    final repo = ref.read(dashboardRepositoryProvider);
    final result = await repo.deleteDashboard(id);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<Dashboard?> duplicateDashboard(String id) async {
    final repo = ref.read(dashboardRepositoryProvider);
    final result = await repo.duplicateDashboard(id);
    return result.when(
      success: (dashboard) {
        ref.invalidateSelf();
        return dashboard;
      },
      failure: (_) => null,
    );
  }
}

final dashboardsProvider =
    AsyncNotifierProvider<DashboardsNotifier, List<Dashboard>>(
      DashboardsNotifier.new,
    );

final dashboardDetailProvider = FutureProvider.family<Dashboard?, String>((
  ref,
  id,
) async {
  ref.watch(offlineAccountProvider);
  final repo = ref.read(dashboardRepositoryProvider);
  final result = await repo.getDashboard(id);
  return result.when(success: (data) => data, failure: (_) => null);
});

final dashboardWidgetsProvider =
    FutureProvider.family<List<DashboardWidget>, String>((
      ref,
      dashboardId,
    ) async {
      ref.watch(offlineAccountProvider);
      final repo = ref.read(dashboardRepositoryProvider);
      final result = await repo.getWidgets(dashboardId);
      return result.when(
        success: (data) => data,
        failure: (_) => <DashboardWidget>[],
      );
    });

final projectDashboardsProvider =
    FutureProvider.family<List<Dashboard>, String>((ref, projectId) async {
      ref.watch(offlineAccountProvider);
      final repo = ref.read(dashboardRepositoryProvider);
      final result = await repo.getDashboards(projectId: projectId);
      return result.when(success: (data) => data, failure: (_) => []);
    });
