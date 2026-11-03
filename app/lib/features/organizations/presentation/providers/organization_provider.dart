import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nexioza/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexioza/features/organizations/data/organization_repository.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(ref.watch(supabaseClientProvider));
});

final organizationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(organizationRepositoryProvider).getOrganizations();
});
