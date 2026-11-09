import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dashboard_repository.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/entities/dashboard_widget_entity.dart';

class DashboardsNotifier extends AsyncNotifier<List<Dashboard>> {
  @override
  Future<List<Dashboard>> build() async {
    final repo = ref.read(dashboardRepositoryProvider);
    final result = await repo.getDashboards();
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<Dashboard?> createDashboard({
    required String projectId,
    required String name,
    String? description,
  }) async {
    final repo = ref.read(dashboardRepositoryProvider);
    final result = await repo.createDashboard(
      projectId: projectId,
      name: name,
      description: description,
    );
    return result.when(
      success: (dashboard) {
        ref.invalidateSelf();
        return dashboard;
      },
      failure: (_) => null,
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
}

final dashboardsProvider =
    AsyncNotifierProvider<DashboardsNotifier, List<Dashboard>>(
      DashboardsNotifier.new,
    );

final dashboardWidgetsProvider =
    FutureProvider.family<List<DashboardWidget>, String>((
      ref,
      dashboardId,
    ) async {
      final repo = ref.read(dashboardRepositoryProvider);
      final result = await repo.getWidgets(dashboardId);
      return result.when(
        success: (data) => data,
        failure: (_) => <DashboardWidget>[],
      );
    });
