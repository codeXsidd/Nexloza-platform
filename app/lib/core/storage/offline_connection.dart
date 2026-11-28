import 'package:sqlite3/common.dart';

typedef OfflineConnection = ({
  CommonDatabase database,
  Future<void> Function() flush,
  Future<void> Function() close,
});
