import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexioza/core/models/profile.dart';
import 'package:nexioza/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexioza/features/profile/data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(profileRepositoryProvider).getProfile();
});
