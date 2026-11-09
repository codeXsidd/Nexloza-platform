import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../shared/models/app_user.dart';
import '../../../core/errors/failures.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<Result<AppUser>> getProfile() async {
    try {
      final userId = _client.auth.currentUser!.id;
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return Result.success(AppUser.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<AppUser>> updateProfile({
    String? fullName,
    String? phone,
    String? bio,
    String? avatarUrl,
    String? timezone,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (timezone != null) updates['timezone'] = timezone;

      final response = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      return Result.success(AppUser.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<AppUser>> getProfileById(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return Result.success(AppUser.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});
