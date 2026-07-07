import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'db.g.dart';

/// Skema lokal mencerminkan skema server (lihat backend/migrations)
/// plus kolom [dirty] untuk menandai perubahan lokal yang belum
/// tersinkronisasi (dipakai di Fase 6).
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get settings => text().withDefault(const Constant('{}'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Boards extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get name => text()();
  IntColumn get gridRows => integer().withDefault(const Constant(4))();
  IntColumn get gridCols => integer().withDefault(const Constant(6))();
  BoolColumn get isRoot => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Cells extends Table {
  TextColumn get id => text()();
  TextColumn get boardId => text().references(Boards, #id)();
  IntColumn get rowIndex => integer()();
  IntColumn get colIndex => integer()();
  TextColumn get label => text()();
  TextColumn get speakText => text().nullable()();
  TextColumn get symbolId => text().nullable()();
  TextColumn get backgroundColor => text().nullable()();

  /// 'speak' atau 'navigate' (sinkron dengan CHECK constraint server).
  TextColumn get actionType => text().withDefault(const Constant('speak'))();
  TextColumn get targetBoardId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Symbols extends Table {
  TextColumn get id => text()();
  TextColumn get pack => text().withDefault(const Constant('custom'))();
  TextColumn get packRef => text().nullable()();
  TextColumn get label => text()();

  /// Disimpan sebagai JSON array string.
  TextColumn get keywords => text().withDefault(const Constant('[]'))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get license => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Profiles, Boards, Cells, Symbols])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'aac'));

  /// Untuk test: pakai executor in-memory.
  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 1;
}
