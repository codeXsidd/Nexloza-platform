import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/automation_repository.dart';
import '../../domain/entities/automation_entity.dart';

class AutomationsNotifier extends AsyncNotifier<List<Automation>> {
  @override
  Future<List<Automation>> build() async {
    final repo = ref.read(automationRepositoryProvider);
    final result = await repo.getAutomations();
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<bool> createAutomation({
    required String projectId,
    required String name,
    String? description,
  }) async {
    final repo = ref.read(automationRepositoryProvider);
    final result = await repo.createAutomation(
      projectId: projectId,
      name: name,
      description: description,
    );
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> toggleAutomation(String id, bool enabled) async {
    final repo = ref.read(automationRepositoryProvider);
    final result = await repo.toggleAutomation(id, enabled);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> deleteAutomation(String id) async {
    final repo = ref.read(automationRepositoryProvider);
    final result = await repo.deleteAutomation(id);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }
}

final automationsProvider =
    AsyncNotifierProvider<AutomationsNotifier, List<Automation>>(
      AutomationsNotifier.new,
    );
