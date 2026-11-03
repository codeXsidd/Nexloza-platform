import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexioza/core/models/organization.dart';
import 'package:nexioza/core/models/organization_member.dart';
import 'package:nexioza/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexioza/features/organizations/data/organization_repository.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(ref.watch(supabaseClientProvider));
});

final organizationsProvider = FutureProvider<List<Organization>>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(organizationRepositoryProvider).getOrganizations();
});

final organizationProvider = FutureProvider.family<Organization?, String>((
  ref,
  orgId,
) async {
  ref.watch(authStateProvider);
  return ref.read(organizationRepositoryProvider).getOrganization(orgId);
});

final organizationMembersProvider =
    FutureProvider.family<List<OrganizationMember>, String>((ref, orgId) async {
      return ref
          .read(organizationRepositoryProvider)
          .getOrganizationMembers(orgId);
    });

final activeOrganizationProvider = StateProvider<String?>((ref) => null);
