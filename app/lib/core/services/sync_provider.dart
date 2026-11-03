import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexioza/core/database/database_provider.dart';
import 'package:nexioza/core/services/sync_service.dart';
import 'package:nexioza/features/auth/presentation/providers/auth_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(supabaseClientProvider),
  );
});
