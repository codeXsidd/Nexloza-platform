import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nexioza/core/database/app_database.dart';
import 'package:nexioza/core/database/connection.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openConnection());
  ref.onDispose(() => db.close());
  return db;
});
