import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/app_user.dart';
import '../../data/profile_repository.dart';

class ProfileNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.getProfile();
    return result.when(success: (user) => user, failure: (_) => null);
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? bio,
    String? avatarUrl,
    String? timezone,
  }) async {
    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.updateProfile(
      fullName: fullName,
      phone: phone,
      bio: bio,
      avatarUrl: avatarUrl,
      timezone: timezone,
    );
    return result.when(
      success: (user) {
        state = AsyncData(user);
        return true;
      },
      failure: (_) => false,
    );
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, AppUser?>(
  ProfileNotifier.new,
);
