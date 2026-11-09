import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/integration_repository.dart';
import '../../domain/entities/integration_entity.dart';

class IntegrationsNotifier extends AsyncNotifier<List<Integration>> {
  @override
  Future<List<Integration>> build() async {
    final repo = ref.read(integrationRepositoryProvider);
    final result = await repo.getIntegrations();
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<bool> createIntegration({
    required String projectId,
    required String name,
    required IntegrationType integrationType,
    Map<String, dynamic> config = const {},
  }) async {
    final repo = ref.read(integrationRepositoryProvider);
    final result = await repo.createIntegration(
      projectId: projectId,
      name: name,
      integrationType: integrationType,
      config: config,
    );
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> toggleIntegration(String id, bool enabled) async {
    final repo = ref.read(integrationRepositoryProvider);
    final result = await repo.toggleIntegration(id, enabled);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> deleteIntegration(String id) async {
    final repo = ref.read(integrationRepositoryProvider);
    final result = await repo.deleteIntegration(id);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }
}

final integrationsProvider =
    AsyncNotifierProvider<IntegrationsNotifier, List<Integration>>(
      IntegrationsNotifier.new,
    );
