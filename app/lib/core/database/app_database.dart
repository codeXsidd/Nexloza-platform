import 'package:drift/drift.dart';

part 'app_database.g.dart';

class LocalProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get avatarUrl => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalOrganizations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get ownerId => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalOrganizationMembers extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalProjects extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get icon => text().withDefault(const Constant('folder'))();
  TextColumn get color => text().withDefault(const Constant('#0891B2'))();
  BoolColumn get isTemplate => boolean().withDefault(const Constant(false))();
  TextColumn get templateId => text().nullable()();
  TextColumn get metadata => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalProjectMembers extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalInvitations extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get invitedEmail => text()();
  TextColumn get invitedBy => text().nullable()();
  TextColumn get role => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalProjectCategories extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get icon => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingMutations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get payload => text()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

class SyncStateTable extends Table {
  TextColumn get entityType => text()();
  IntColumn get lastSeq => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  String get tableName => 'sync_state';

  @override
  Set<Column> get primaryKey => {entityType};
}

@DriftDatabase(
  tables: [
    LocalProfiles,
    LocalOrganizations,
    LocalOrganizationMembers,
    LocalProjects,
    LocalProjectMembers,
    LocalInvitations,
    LocalProjectCategories,
    PendingMutations,
    SyncStateTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
    );
  }
}
