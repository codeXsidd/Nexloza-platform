import 'dart:typed_data';

import 'package:nexioza/core/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  Future<Profile?> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<void> updateProfile({
    required int expectedVersion,
    String? displayName,
    String? avatarUrl,
  }) async {
    await _client.rpc<void>(
      'update_profile',
      params: {
        '_expected_version': expectedVersion,
        '_display_name': displayName,
        '_avatar_url': avatarUrl,
      },
    );
  }

  Future<String> uploadAvatar(String fileName, Uint8List bytes) async {
    final userId = _client.auth.currentUser!.id;
    final path = '$userId/$fileName';
    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  Future<void> removeAvatar(String path) async {
    await _client.storage.from('avatars').remove([path]);
  }

  Future<void> deleteAccount() async {
    await _client.rpc<void>('delete_own_account');
  }
}
