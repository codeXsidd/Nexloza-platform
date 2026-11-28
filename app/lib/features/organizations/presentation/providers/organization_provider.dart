import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/offline_sync_service.dart';
import '../../data/organization_repository.dart';
import '../../domain/entities/organization_entity.dart';

class OrganizationsNotifier extends AsyncNotifier<List<Organization>> {
  @override
  Future<List<Organization>> build() async {
    ref.watch(offlineAccountProvider);
    final repo = ref.read(organizationRepositoryProvider);
    final result = await repo.getOrganizations();
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<bool> createOrganization({
    required String name,
    String? description,
  }) async {
    final repo = ref.read(organizationRepositoryProvider);
    final result = await repo.createOrganization(
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

  Future<bool> updateOrganization(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final repo = ref.read(organizationRepositoryProvider);
    final result = await repo.updateOrganization(id, updates);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> deleteOrganization(String id) async {
    final repo = ref.read(organizationRepositoryProvider);
    final result = await repo.deleteOrganization(id);
    return result.when(
      success: (_) {
        ref.invalidateSelf();
        return true;
      },
      failure: (_) => false,
    );
  }
}

final organizationsProvider =
    AsyncNotifierProvider<OrganizationsNotifier, List<Organization>>(
      OrganizationsNotifier.new,
    );

final organizationDetailProvider = FutureProvider.family<Organization?, String>(
  (ref, id) async {
    ref.watch(offlineAccountProvider);
    final repo = ref.read(organizationRepositoryProvider);
    final result = await repo.getOrganization(id);
    return result.when(success: (org) => org, failure: (_) => null);
  },
);

final orgMembersProvider = FutureProvider.family<List<OrgMember>, String>((
  ref,
  orgId,
) async {
  ref.watch(offlineAccountProvider);
  final repo = ref.read(organizationRepositoryProvider);
  final result = await repo.getMembers(orgId);
  return result.when(success: (members) => members, failure: (_) => []);
});

final currentUserOrgRoleProvider = FutureProvider.family<OrgRole?, String>((
  ref,
  orgId,
) async {
  ref.watch(offlineAccountProvider);
  final repo = ref.read(organizationRepositoryProvider);
  final result = await repo.getCurrentUserRole(orgId);
  return result.when(success: (role) => role, failure: (_) => null);
});
