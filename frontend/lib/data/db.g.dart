// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _settingsMeta =
      const VerificationMeta('settings');
  @override
  late final GeneratedColumn<String> settings = GeneratedColumn<String>(
      'settings', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, settings, updatedAt, deletedAt, dirty];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<Profile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('settings')) {
      context.handle(_settingsMeta,
          settings.isAcceptableOrUnknown(data['settings']!, _settingsMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      settings: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}settings'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String name;
  final String settings;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const Profile(
      {required this.id,
      required this.name,
      required this.settings,
      required this.updatedAt,
      this.deletedAt,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['settings'] = Variable<String>(settings);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      settings: Value(settings),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      settings: serializer.fromJson<String>(json['settings']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'settings': serializer.toJson<String>(settings),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Profile copyWith(
          {String? id,
          String? name,
          String? settings,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? dirty}) =>
      Profile(
        id: id ?? this.id,
        name: name ?? this.name,
        settings: settings ?? this.settings,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        dirty: dirty ?? this.dirty,
      );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      settings: data.settings.present ? data.settings.value : this.settings,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('settings: $settings, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, settings, updatedAt, deletedAt, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.settings == this.settings &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> settings;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.settings = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String name,
    this.settings = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? settings,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (settings != null) 'settings': settings,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? settings,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      settings: settings ?? this.settings,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (settings.present) {
      map['settings'] = Variable<String>(settings.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('settings: $settings, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardsTable extends Boards with TableInfo<$BoardsTable, Board> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profile_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES profiles (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _gridRowsMeta =
      const VerificationMeta('gridRows');
  @override
  late final GeneratedColumn<int> gridRows = GeneratedColumn<int>(
      'grid_rows', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(4));
  static const VerificationMeta _gridColsMeta =
      const VerificationMeta('gridCols');
  @override
  late final GeneratedColumn<int> gridCols = GeneratedColumn<int>(
      'grid_cols', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(6));
  static const VerificationMeta _isRootMeta = const VerificationMeta('isRoot');
  @override
  late final GeneratedColumn<bool> isRoot = GeneratedColumn<bool>(
      'is_root', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_root" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        name,
        gridRows,
        gridCols,
        isRoot,
        updatedAt,
        deletedAt,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'boards';
  @override
  VerificationContext validateIntegrity(Insertable<Board> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grid_rows')) {
      context.handle(_gridRowsMeta,
          gridRows.isAcceptableOrUnknown(data['grid_rows']!, _gridRowsMeta));
    }
    if (data.containsKey('grid_cols')) {
      context.handle(_gridColsMeta,
          gridCols.isAcceptableOrUnknown(data['grid_cols']!, _gridColsMeta));
    }
    if (data.containsKey('is_root')) {
      context.handle(_isRootMeta,
          isRoot.isAcceptableOrUnknown(data['is_root']!, _isRootMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Board map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Board(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      gridRows: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}grid_rows'])!,
      gridCols: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}grid_cols'])!,
      isRoot: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_root'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $BoardsTable createAlias(String alias) {
    return $BoardsTable(attachedDatabase, alias);
  }
}

class Board extends DataClass implements Insertable<Board> {
  final String id;
  final String profileId;
  final String name;
  final int gridRows;
  final int gridCols;
  final bool isRoot;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const Board(
      {required this.id,
      required this.profileId,
      required this.name,
      required this.gridRows,
      required this.gridCols,
      required this.isRoot,
      required this.updatedAt,
      this.deletedAt,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['name'] = Variable<String>(name);
    map['grid_rows'] = Variable<int>(gridRows);
    map['grid_cols'] = Variable<int>(gridCols);
    map['is_root'] = Variable<bool>(isRoot);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  BoardsCompanion toCompanion(bool nullToAbsent) {
    return BoardsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      gridRows: Value(gridRows),
      gridCols: Value(gridCols),
      isRoot: Value(isRoot),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory Board.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Board(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      gridRows: serializer.fromJson<int>(json['gridRows']),
      gridCols: serializer.fromJson<int>(json['gridCols']),
      isRoot: serializer.fromJson<bool>(json['isRoot']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'name': serializer.toJson<String>(name),
      'gridRows': serializer.toJson<int>(gridRows),
      'gridCols': serializer.toJson<int>(gridCols),
      'isRoot': serializer.toJson<bool>(isRoot),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Board copyWith(
          {String? id,
          String? profileId,
          String? name,
          int? gridRows,
          int? gridCols,
          bool? isRoot,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? dirty}) =>
      Board(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        name: name ?? this.name,
        gridRows: gridRows ?? this.gridRows,
        gridCols: gridCols ?? this.gridCols,
        isRoot: isRoot ?? this.isRoot,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        dirty: dirty ?? this.dirty,
      );
  Board copyWithCompanion(BoardsCompanion data) {
    return Board(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      gridRows: data.gridRows.present ? data.gridRows.value : this.gridRows,
      gridCols: data.gridCols.present ? data.gridCols.value : this.gridCols,
      isRoot: data.isRoot.present ? data.isRoot.value : this.isRoot,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Board(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('gridRows: $gridRows, ')
          ..write('gridCols: $gridCols, ')
          ..write('isRoot: $isRoot, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, name, gridRows, gridCols,
      isRoot, updatedAt, deletedAt, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Board &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.gridRows == this.gridRows &&
          other.gridCols == this.gridCols &&
          other.isRoot == this.isRoot &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class BoardsCompanion extends UpdateCompanion<Board> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> name;
  final Value<int> gridRows;
  final Value<int> gridCols;
  final Value<bool> isRoot;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const BoardsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.gridRows = const Value.absent(),
    this.gridCols = const Value.absent(),
    this.isRoot = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardsCompanion.insert({
    required String id,
    required String profileId,
    required String name,
    this.gridRows = const Value.absent(),
    this.gridCols = const Value.absent(),
    this.isRoot = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        name = Value(name);
  static Insertable<Board> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? name,
    Expression<int>? gridRows,
    Expression<int>? gridCols,
    Expression<bool>? isRoot,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (gridRows != null) 'grid_rows': gridRows,
      if (gridCols != null) 'grid_cols': gridCols,
      if (isRoot != null) 'is_root': isRoot,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardsCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<String>? name,
      Value<int>? gridRows,
      Value<int>? gridCols,
      Value<bool>? isRoot,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return BoardsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      gridRows: gridRows ?? this.gridRows,
      gridCols: gridCols ?? this.gridCols,
      isRoot: isRoot ?? this.isRoot,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gridRows.present) {
      map['grid_rows'] = Variable<int>(gridRows.value);
    }
    if (gridCols.present) {
      map['grid_cols'] = Variable<int>(gridCols.value);
    }
    if (isRoot.present) {
      map['is_root'] = Variable<bool>(isRoot.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('gridRows: $gridRows, ')
          ..write('gridCols: $gridCols, ')
          ..write('isRoot: $isRoot, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CellsTable extends Cells with TableInfo<$CellsTable, Cell> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CellsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _boardIdMeta =
      const VerificationMeta('boardId');
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
      'board_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES boards (id)'));
  static const VerificationMeta _rowIndexMeta =
      const VerificationMeta('rowIndex');
  @override
  late final GeneratedColumn<int> rowIndex = GeneratedColumn<int>(
      'row_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _colIndexMeta =
      const VerificationMeta('colIndex');
  @override
  late final GeneratedColumn<int> colIndex = GeneratedColumn<int>(
      'col_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _speakTextMeta =
      const VerificationMeta('speakText');
  @override
  late final GeneratedColumn<String> speakText = GeneratedColumn<String>(
      'speak_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _symbolIdMeta =
      const VerificationMeta('symbolId');
  @override
  late final GeneratedColumn<String> symbolId = GeneratedColumn<String>(
      'symbol_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _backgroundColorMeta =
      const VerificationMeta('backgroundColor');
  @override
  late final GeneratedColumn<String> backgroundColor = GeneratedColumn<String>(
      'background_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actionTypeMeta =
      const VerificationMeta('actionType');
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
      'action_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('speak'));
  static const VerificationMeta _targetBoardIdMeta =
      const VerificationMeta('targetBoardId');
  @override
  late final GeneratedColumn<String> targetBoardId = GeneratedColumn<String>(
      'target_board_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        boardId,
        rowIndex,
        colIndex,
        label,
        speakText,
        symbolId,
        backgroundColor,
        actionType,
        targetBoardId,
        updatedAt,
        deletedAt,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cells';
  @override
  VerificationContext validateIntegrity(Insertable<Cell> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(_boardIdMeta,
          boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta));
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('row_index')) {
      context.handle(_rowIndexMeta,
          rowIndex.isAcceptableOrUnknown(data['row_index']!, _rowIndexMeta));
    } else if (isInserting) {
      context.missing(_rowIndexMeta);
    }
    if (data.containsKey('col_index')) {
      context.handle(_colIndexMeta,
          colIndex.isAcceptableOrUnknown(data['col_index']!, _colIndexMeta));
    } else if (isInserting) {
      context.missing(_colIndexMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('speak_text')) {
      context.handle(_speakTextMeta,
          speakText.isAcceptableOrUnknown(data['speak_text']!, _speakTextMeta));
    }
    if (data.containsKey('symbol_id')) {
      context.handle(_symbolIdMeta,
          symbolId.isAcceptableOrUnknown(data['symbol_id']!, _symbolIdMeta));
    }
    if (data.containsKey('background_color')) {
      context.handle(
          _backgroundColorMeta,
          backgroundColor.isAcceptableOrUnknown(
              data['background_color']!, _backgroundColorMeta));
    }
    if (data.containsKey('action_type')) {
      context.handle(
          _actionTypeMeta,
          actionType.isAcceptableOrUnknown(
              data['action_type']!, _actionTypeMeta));
    }
    if (data.containsKey('target_board_id')) {
      context.handle(
          _targetBoardIdMeta,
          targetBoardId.isAcceptableOrUnknown(
              data['target_board_id']!, _targetBoardIdMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cell map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cell(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      boardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}board_id'])!,
      rowIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}row_index'])!,
      colIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}col_index'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      speakText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}speak_text']),
      symbolId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symbol_id']),
      backgroundColor: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}background_color']),
      actionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action_type'])!,
      targetBoardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_board_id']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $CellsTable createAlias(String alias) {
    return $CellsTable(attachedDatabase, alias);
  }
}

class Cell extends DataClass implements Insertable<Cell> {
  final String id;
  final String boardId;
  final int rowIndex;
  final int colIndex;
  final String label;
  final String? speakText;
  final String? symbolId;
  final String? backgroundColor;

  /// 'speak' atau 'navigate' (sinkron dengan CHECK constraint server).
  final String actionType;
  final String? targetBoardId;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const Cell(
      {required this.id,
      required this.boardId,
      required this.rowIndex,
      required this.colIndex,
      required this.label,
      this.speakText,
      this.symbolId,
      this.backgroundColor,
      required this.actionType,
      this.targetBoardId,
      required this.updatedAt,
      this.deletedAt,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['board_id'] = Variable<String>(boardId);
    map['row_index'] = Variable<int>(rowIndex);
    map['col_index'] = Variable<int>(colIndex);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || speakText != null) {
      map['speak_text'] = Variable<String>(speakText);
    }
    if (!nullToAbsent || symbolId != null) {
      map['symbol_id'] = Variable<String>(symbolId);
    }
    if (!nullToAbsent || backgroundColor != null) {
      map['background_color'] = Variable<String>(backgroundColor);
    }
    map['action_type'] = Variable<String>(actionType);
    if (!nullToAbsent || targetBoardId != null) {
      map['target_board_id'] = Variable<String>(targetBoardId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  CellsCompanion toCompanion(bool nullToAbsent) {
    return CellsCompanion(
      id: Value(id),
      boardId: Value(boardId),
      rowIndex: Value(rowIndex),
      colIndex: Value(colIndex),
      label: Value(label),
      speakText: speakText == null && nullToAbsent
          ? const Value.absent()
          : Value(speakText),
      symbolId: symbolId == null && nullToAbsent
          ? const Value.absent()
          : Value(symbolId),
      backgroundColor: backgroundColor == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundColor),
      actionType: Value(actionType),
      targetBoardId: targetBoardId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetBoardId),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory Cell.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cell(
      id: serializer.fromJson<String>(json['id']),
      boardId: serializer.fromJson<String>(json['boardId']),
      rowIndex: serializer.fromJson<int>(json['rowIndex']),
      colIndex: serializer.fromJson<int>(json['colIndex']),
      label: serializer.fromJson<String>(json['label']),
      speakText: serializer.fromJson<String?>(json['speakText']),
      symbolId: serializer.fromJson<String?>(json['symbolId']),
      backgroundColor: serializer.fromJson<String?>(json['backgroundColor']),
      actionType: serializer.fromJson<String>(json['actionType']),
      targetBoardId: serializer.fromJson<String?>(json['targetBoardId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'boardId': serializer.toJson<String>(boardId),
      'rowIndex': serializer.toJson<int>(rowIndex),
      'colIndex': serializer.toJson<int>(colIndex),
      'label': serializer.toJson<String>(label),
      'speakText': serializer.toJson<String?>(speakText),
      'symbolId': serializer.toJson<String?>(symbolId),
      'backgroundColor': serializer.toJson<String?>(backgroundColor),
      'actionType': serializer.toJson<String>(actionType),
      'targetBoardId': serializer.toJson<String?>(targetBoardId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Cell copyWith(
          {String? id,
          String? boardId,
          int? rowIndex,
          int? colIndex,
          String? label,
          Value<String?> speakText = const Value.absent(),
          Value<String?> symbolId = const Value.absent(),
          Value<String?> backgroundColor = const Value.absent(),
          String? actionType,
          Value<String?> targetBoardId = const Value.absent(),
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? dirty}) =>
      Cell(
        id: id ?? this.id,
        boardId: boardId ?? this.boardId,
        rowIndex: rowIndex ?? this.rowIndex,
        colIndex: colIndex ?? this.colIndex,
        label: label ?? this.label,
        speakText: speakText.present ? speakText.value : this.speakText,
        symbolId: symbolId.present ? symbolId.value : this.symbolId,
        backgroundColor: backgroundColor.present
            ? backgroundColor.value
            : this.backgroundColor,
        actionType: actionType ?? this.actionType,
        targetBoardId:
            targetBoardId.present ? targetBoardId.value : this.targetBoardId,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        dirty: dirty ?? this.dirty,
      );
  Cell copyWithCompanion(CellsCompanion data) {
    return Cell(
      id: data.id.present ? data.id.value : this.id,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      rowIndex: data.rowIndex.present ? data.rowIndex.value : this.rowIndex,
      colIndex: data.colIndex.present ? data.colIndex.value : this.colIndex,
      label: data.label.present ? data.label.value : this.label,
      speakText: data.speakText.present ? data.speakText.value : this.speakText,
      symbolId: data.symbolId.present ? data.symbolId.value : this.symbolId,
      backgroundColor: data.backgroundColor.present
          ? data.backgroundColor.value
          : this.backgroundColor,
      actionType:
          data.actionType.present ? data.actionType.value : this.actionType,
      targetBoardId: data.targetBoardId.present
          ? data.targetBoardId.value
          : this.targetBoardId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cell(')
          ..write('id: $id, ')
          ..write('boardId: $boardId, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('colIndex: $colIndex, ')
          ..write('label: $label, ')
          ..write('speakText: $speakText, ')
          ..write('symbolId: $symbolId, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('actionType: $actionType, ')
          ..write('targetBoardId: $targetBoardId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      boardId,
      rowIndex,
      colIndex,
      label,
      speakText,
      symbolId,
      backgroundColor,
      actionType,
      targetBoardId,
      updatedAt,
      deletedAt,
      dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cell &&
          other.id == this.id &&
          other.boardId == this.boardId &&
          other.rowIndex == this.rowIndex &&
          other.colIndex == this.colIndex &&
          other.label == this.label &&
          other.speakText == this.speakText &&
          other.symbolId == this.symbolId &&
          other.backgroundColor == this.backgroundColor &&
          other.actionType == this.actionType &&
          other.targetBoardId == this.targetBoardId &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class CellsCompanion extends UpdateCompanion<Cell> {
  final Value<String> id;
  final Value<String> boardId;
  final Value<int> rowIndex;
  final Value<int> colIndex;
  final Value<String> label;
  final Value<String?> speakText;
  final Value<String?> symbolId;
  final Value<String?> backgroundColor;
  final Value<String> actionType;
  final Value<String?> targetBoardId;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const CellsCompanion({
    this.id = const Value.absent(),
    this.boardId = const Value.absent(),
    this.rowIndex = const Value.absent(),
    this.colIndex = const Value.absent(),
    this.label = const Value.absent(),
    this.speakText = const Value.absent(),
    this.symbolId = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.actionType = const Value.absent(),
    this.targetBoardId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CellsCompanion.insert({
    required String id,
    required String boardId,
    required int rowIndex,
    required int colIndex,
    required String label,
    this.speakText = const Value.absent(),
    this.symbolId = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.actionType = const Value.absent(),
    this.targetBoardId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        boardId = Value(boardId),
        rowIndex = Value(rowIndex),
        colIndex = Value(colIndex),
        label = Value(label);
  static Insertable<Cell> custom({
    Expression<String>? id,
    Expression<String>? boardId,
    Expression<int>? rowIndex,
    Expression<int>? colIndex,
    Expression<String>? label,
    Expression<String>? speakText,
    Expression<String>? symbolId,
    Expression<String>? backgroundColor,
    Expression<String>? actionType,
    Expression<String>? targetBoardId,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boardId != null) 'board_id': boardId,
      if (rowIndex != null) 'row_index': rowIndex,
      if (colIndex != null) 'col_index': colIndex,
      if (label != null) 'label': label,
      if (speakText != null) 'speak_text': speakText,
      if (symbolId != null) 'symbol_id': symbolId,
      if (backgroundColor != null) 'background_color': backgroundColor,
      if (actionType != null) 'action_type': actionType,
      if (targetBoardId != null) 'target_board_id': targetBoardId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CellsCompanion copyWith(
      {Value<String>? id,
      Value<String>? boardId,
      Value<int>? rowIndex,
      Value<int>? colIndex,
      Value<String>? label,
      Value<String?>? speakText,
      Value<String?>? symbolId,
      Value<String?>? backgroundColor,
      Value<String>? actionType,
      Value<String?>? targetBoardId,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return CellsCompanion(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      rowIndex: rowIndex ?? this.rowIndex,
      colIndex: colIndex ?? this.colIndex,
      label: label ?? this.label,
      speakText: speakText ?? this.speakText,
      symbolId: symbolId ?? this.symbolId,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      actionType: actionType ?? this.actionType,
      targetBoardId: targetBoardId ?? this.targetBoardId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (rowIndex.present) {
      map['row_index'] = Variable<int>(rowIndex.value);
    }
    if (colIndex.present) {
      map['col_index'] = Variable<int>(colIndex.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (speakText.present) {
      map['speak_text'] = Variable<String>(speakText.value);
    }
    if (symbolId.present) {
      map['symbol_id'] = Variable<String>(symbolId.value);
    }
    if (backgroundColor.present) {
      map['background_color'] = Variable<String>(backgroundColor.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (targetBoardId.present) {
      map['target_board_id'] = Variable<String>(targetBoardId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CellsCompanion(')
          ..write('id: $id, ')
          ..write('boardId: $boardId, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('colIndex: $colIndex, ')
          ..write('label: $label, ')
          ..write('speakText: $speakText, ')
          ..write('symbolId: $symbolId, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('actionType: $actionType, ')
          ..write('targetBoardId: $targetBoardId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SymbolsTable extends Symbols with TableInfo<$SymbolsTable, Symbol> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SymbolsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _packMeta = const VerificationMeta('pack');
  @override
  late final GeneratedColumn<String> pack = GeneratedColumn<String>(
      'pack', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('custom'));
  static const VerificationMeta _packRefMeta =
      const VerificationMeta('packRef');
  @override
  late final GeneratedColumn<String> packRef = GeneratedColumn<String>(
      'pack_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _keywordsMeta =
      const VerificationMeta('keywords');
  @override
  late final GeneratedColumn<String> keywords = GeneratedColumn<String>(
      'keywords', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _licenseMeta =
      const VerificationMeta('license');
  @override
  late final GeneratedColumn<String> license = GeneratedColumn<String>(
      'license', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
      'dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dirty" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        pack,
        packRef,
        label,
        category,
        keywords,
        imageUrl,
        license,
        updatedAt,
        deletedAt,
        dirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'symbols';
  @override
  VerificationContext validateIntegrity(Insertable<Symbol> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pack')) {
      context.handle(
          _packMeta, pack.isAcceptableOrUnknown(data['pack']!, _packMeta));
    }
    if (data.containsKey('pack_ref')) {
      context.handle(_packRefMeta,
          packRef.isAcceptableOrUnknown(data['pack_ref']!, _packRefMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('keywords')) {
      context.handle(_keywordsMeta,
          keywords.isAcceptableOrUnknown(data['keywords']!, _keywordsMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('license')) {
      context.handle(_licenseMeta,
          license.isAcceptableOrUnknown(data['license']!, _licenseMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('dirty')) {
      context.handle(
          _dirtyMeta, dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Symbol map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Symbol(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      pack: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pack'])!,
      packRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pack_ref']),
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      keywords: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}keywords'])!,
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      license: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}license']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      dirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dirty'])!,
    );
  }

  @override
  $SymbolsTable createAlias(String alias) {
    return $SymbolsTable(attachedDatabase, alias);
  }
}

class Symbol extends DataClass implements Insertable<Symbol> {
  final String id;
  final String pack;
  final String? packRef;
  final String label;
  final String? category;

  /// Disimpan sebagai JSON array string.
  final String keywords;
  final String? imageUrl;
  final String? license;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool dirty;
  const Symbol(
      {required this.id,
      required this.pack,
      this.packRef,
      required this.label,
      this.category,
      required this.keywords,
      this.imageUrl,
      this.license,
      required this.updatedAt,
      this.deletedAt,
      required this.dirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pack'] = Variable<String>(pack);
    if (!nullToAbsent || packRef != null) {
      map['pack_ref'] = Variable<String>(packRef);
    }
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['keywords'] = Variable<String>(keywords);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || license != null) {
      map['license'] = Variable<String>(license);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['dirty'] = Variable<bool>(dirty);
    return map;
  }

  SymbolsCompanion toCompanion(bool nullToAbsent) {
    return SymbolsCompanion(
      id: Value(id),
      pack: Value(pack),
      packRef: packRef == null && nullToAbsent
          ? const Value.absent()
          : Value(packRef),
      label: Value(label),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      keywords: Value(keywords),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      license: license == null && nullToAbsent
          ? const Value.absent()
          : Value(license),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  factory Symbol.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Symbol(
      id: serializer.fromJson<String>(json['id']),
      pack: serializer.fromJson<String>(json['pack']),
      packRef: serializer.fromJson<String?>(json['packRef']),
      label: serializer.fromJson<String>(json['label']),
      category: serializer.fromJson<String?>(json['category']),
      keywords: serializer.fromJson<String>(json['keywords']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      license: serializer.fromJson<String?>(json['license']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      dirty: serializer.fromJson<bool>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pack': serializer.toJson<String>(pack),
      'packRef': serializer.toJson<String?>(packRef),
      'label': serializer.toJson<String>(label),
      'category': serializer.toJson<String?>(category),
      'keywords': serializer.toJson<String>(keywords),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'license': serializer.toJson<String?>(license),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'dirty': serializer.toJson<bool>(dirty),
    };
  }

  Symbol copyWith(
          {String? id,
          String? pack,
          Value<String?> packRef = const Value.absent(),
          String? label,
          Value<String?> category = const Value.absent(),
          String? keywords,
          Value<String?> imageUrl = const Value.absent(),
          Value<String?> license = const Value.absent(),
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? dirty}) =>
      Symbol(
        id: id ?? this.id,
        pack: pack ?? this.pack,
        packRef: packRef.present ? packRef.value : this.packRef,
        label: label ?? this.label,
        category: category.present ? category.value : this.category,
        keywords: keywords ?? this.keywords,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        license: license.present ? license.value : this.license,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        dirty: dirty ?? this.dirty,
      );
  Symbol copyWithCompanion(SymbolsCompanion data) {
    return Symbol(
      id: data.id.present ? data.id.value : this.id,
      pack: data.pack.present ? data.pack.value : this.pack,
      packRef: data.packRef.present ? data.packRef.value : this.packRef,
      label: data.label.present ? data.label.value : this.label,
      category: data.category.present ? data.category.value : this.category,
      keywords: data.keywords.present ? data.keywords.value : this.keywords,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      license: data.license.present ? data.license.value : this.license,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Symbol(')
          ..write('id: $id, ')
          ..write('pack: $pack, ')
          ..write('packRef: $packRef, ')
          ..write('label: $label, ')
          ..write('category: $category, ')
          ..write('keywords: $keywords, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('license: $license, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pack, packRef, label, category, keywords,
      imageUrl, license, updatedAt, deletedAt, dirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Symbol &&
          other.id == this.id &&
          other.pack == this.pack &&
          other.packRef == this.packRef &&
          other.label == this.label &&
          other.category == this.category &&
          other.keywords == this.keywords &&
          other.imageUrl == this.imageUrl &&
          other.license == this.license &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.dirty == this.dirty);
}

class SymbolsCompanion extends UpdateCompanion<Symbol> {
  final Value<String> id;
  final Value<String> pack;
  final Value<String?> packRef;
  final Value<String> label;
  final Value<String?> category;
  final Value<String> keywords;
  final Value<String?> imageUrl;
  final Value<String?> license;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> dirty;
  final Value<int> rowid;
  const SymbolsCompanion({
    this.id = const Value.absent(),
    this.pack = const Value.absent(),
    this.packRef = const Value.absent(),
    this.label = const Value.absent(),
    this.category = const Value.absent(),
    this.keywords = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.license = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SymbolsCompanion.insert({
    required String id,
    this.pack = const Value.absent(),
    this.packRef = const Value.absent(),
    required String label,
    this.category = const Value.absent(),
    this.keywords = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.license = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        label = Value(label);
  static Insertable<Symbol> custom({
    Expression<String>? id,
    Expression<String>? pack,
    Expression<String>? packRef,
    Expression<String>? label,
    Expression<String>? category,
    Expression<String>? keywords,
    Expression<String>? imageUrl,
    Expression<String>? license,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pack != null) 'pack': pack,
      if (packRef != null) 'pack_ref': packRef,
      if (label != null) 'label': label,
      if (category != null) 'category': category,
      if (keywords != null) 'keywords': keywords,
      if (imageUrl != null) 'image_url': imageUrl,
      if (license != null) 'license': license,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SymbolsCompanion copyWith(
      {Value<String>? id,
      Value<String>? pack,
      Value<String?>? packRef,
      Value<String>? label,
      Value<String?>? category,
      Value<String>? keywords,
      Value<String?>? imageUrl,
      Value<String?>? license,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? dirty,
      Value<int>? rowid}) {
    return SymbolsCompanion(
      id: id ?? this.id,
      pack: pack ?? this.pack,
      packRef: packRef ?? this.packRef,
      label: label ?? this.label,
      category: category ?? this.category,
      keywords: keywords ?? this.keywords,
      imageUrl: imageUrl ?? this.imageUrl,
      license: license ?? this.license,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pack.present) {
      map['pack'] = Variable<String>(pack.value);
    }
    if (packRef.present) {
      map['pack_ref'] = Variable<String>(packRef.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (keywords.present) {
      map['keywords'] = Variable<String>(keywords.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (license.present) {
      map['license'] = Variable<String>(license.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SymbolsCompanion(')
          ..write('id: $id, ')
          ..write('pack: $pack, ')
          ..write('packRef: $packRef, ')
          ..write('label: $label, ')
          ..write('category: $category, ')
          ..write('keywords: $keywords, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('license: $license, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $BoardsTable boards = $BoardsTable(this);
  late final $CellsTable cells = $CellsTable(this);
  late final $SymbolsTable symbols = $SymbolsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [profiles, boards, cells, symbols];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required String id,
  required String name,
  Value<String> settings,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> settings,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});

final class $$ProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $ProfilesTable, Profile> {
  $$ProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BoardsTable, List<Board>> _boardsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.boards,
          aliasName: 'profiles__id__boards__profile_id');

  $$BoardsTableProcessedTableManager get boardsRefs {
    final manager = $$BoardsTableTableManager($_db, $_db.boards)
        .filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_boardsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get settings => $composableBuilder(
      column: $table.settings, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));

  Expression<bool> boardsRefs(
      Expression<bool> Function($$BoardsTableFilterComposer f) f) {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.boards,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BoardsTableFilterComposer(
              $db: $db,
              $table: $db.boards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get settings => $composableBuilder(
      column: $table.settings, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get settings =>
      $composableBuilder(column: $table.settings, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  Expression<T> boardsRefs<T extends Object>(
      Expression<T> Function($$BoardsTableAnnotationComposer a) f) {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.boards,
        getReferencedColumn: (t) => t.profileId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BoardsTableAnnotationComposer(
              $db: $db,
              $table: $db.boards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, $$ProfilesTableReferences),
    Profile,
    PrefetchHooks Function({bool boardsRefs})> {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> settings = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesCompanion(
            id: id,
            name: name,
            settings: settings,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> settings = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesCompanion.insert(
            id: id,
            name: name,
            settings: settings,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProfilesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({boardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (boardsRefs) db.boards],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (boardsRefs)
                    await $_getPrefetchedData<Profile, $ProfilesTable, Board>(
                        currentTable: table,
                        referencedTable:
                            $$ProfilesTableReferences._boardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProfilesTableReferences(db, table, p0).boardsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.profileId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProfilesTable,
    Profile,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (Profile, $$ProfilesTableReferences),
    Profile,
    PrefetchHooks Function({bool boardsRefs})>;
typedef $$BoardsTableCreateCompanionBuilder = BoardsCompanion Function({
  required String id,
  required String profileId,
  required String name,
  Value<int> gridRows,
  Value<int> gridCols,
  Value<bool> isRoot,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$BoardsTableUpdateCompanionBuilder = BoardsCompanion Function({
  Value<String> id,
  Value<String> profileId,
  Value<String> name,
  Value<int> gridRows,
  Value<int> gridCols,
  Value<bool> isRoot,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});

final class $$BoardsTableReferences
    extends BaseReferences<_$AppDatabase, $BoardsTable, Board> {
  $$BoardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProfilesTable _profileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias('boards__profile_id__profiles__id');

  $$ProfilesTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<String>('profile_id')!;

    final manager = $$ProfilesTableTableManager($_db, $_db.profiles)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$CellsTable, List<Cell>> _cellsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.cells,
          aliasName: 'boards__id__cells__board_id');

  $$CellsTableProcessedTableManager get cellsRefs {
    final manager = $$CellsTableTableManager($_db, $_db.cells)
        .filter((f) => f.boardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cellsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BoardsTableFilterComposer
    extends Composer<_$AppDatabase, $BoardsTable> {
  $$BoardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gridRows => $composableBuilder(
      column: $table.gridRows, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gridCols => $composableBuilder(
      column: $table.gridCols, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRoot => $composableBuilder(
      column: $table.isRoot, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));

  $$ProfilesTableFilterComposer get profileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableFilterComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> cellsRefs(
      Expression<bool> Function($$CellsTableFilterComposer f) f) {
    final $$CellsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cells,
        getReferencedColumn: (t) => t.boardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CellsTableFilterComposer(
              $db: $db,
              $table: $db.cells,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BoardsTableOrderingComposer
    extends Composer<_$AppDatabase, $BoardsTable> {
  $$BoardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gridRows => $composableBuilder(
      column: $table.gridRows, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gridCols => $composableBuilder(
      column: $table.gridCols, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRoot => $composableBuilder(
      column: $table.isRoot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));

  $$ProfilesTableOrderingComposer get profileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableOrderingComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BoardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoardsTable> {
  $$BoardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get gridRows =>
      $composableBuilder(column: $table.gridRows, builder: (column) => column);

  GeneratedColumn<int> get gridCols =>
      $composableBuilder(column: $table.gridCols, builder: (column) => column);

  GeneratedColumn<bool> get isRoot =>
      $composableBuilder(column: $table.isRoot, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  $$ProfilesTableAnnotationComposer get profileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.profileId,
        referencedTable: $db.profiles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProfilesTableAnnotationComposer(
              $db: $db,
              $table: $db.profiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> cellsRefs<T extends Object>(
      Expression<T> Function($$CellsTableAnnotationComposer a) f) {
    final $$CellsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cells,
        getReferencedColumn: (t) => t.boardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CellsTableAnnotationComposer(
              $db: $db,
              $table: $db.cells,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BoardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BoardsTable,
    Board,
    $$BoardsTableFilterComposer,
    $$BoardsTableOrderingComposer,
    $$BoardsTableAnnotationComposer,
    $$BoardsTableCreateCompanionBuilder,
    $$BoardsTableUpdateCompanionBuilder,
    (Board, $$BoardsTableReferences),
    Board,
    PrefetchHooks Function({bool profileId, bool cellsRefs})> {
  $$BoardsTableTableManager(_$AppDatabase db, $BoardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> gridRows = const Value.absent(),
            Value<int> gridCols = const Value.absent(),
            Value<bool> isRoot = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BoardsCompanion(
            id: id,
            profileId: profileId,
            name: name,
            gridRows: gridRows,
            gridCols: gridCols,
            isRoot: isRoot,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required String name,
            Value<int> gridRows = const Value.absent(),
            Value<int> gridCols = const Value.absent(),
            Value<bool> isRoot = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BoardsCompanion.insert(
            id: id,
            profileId: profileId,
            name: name,
            gridRows: gridRows,
            gridCols: gridCols,
            isRoot: isRoot,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$BoardsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({profileId = false, cellsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cellsRefs) db.cells],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (profileId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.profileId,
                    referencedTable:
                        $$BoardsTableReferences._profileIdTable(db),
                    referencedColumn:
                        $$BoardsTableReferences._profileIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cellsRefs)
                    await $_getPrefetchedData<Board, $BoardsTable, Cell>(
                        currentTable: table,
                        referencedTable:
                            $$BoardsTableReferences._cellsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BoardsTableReferences(db, table, p0).cellsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.boardId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BoardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BoardsTable,
    Board,
    $$BoardsTableFilterComposer,
    $$BoardsTableOrderingComposer,
    $$BoardsTableAnnotationComposer,
    $$BoardsTableCreateCompanionBuilder,
    $$BoardsTableUpdateCompanionBuilder,
    (Board, $$BoardsTableReferences),
    Board,
    PrefetchHooks Function({bool profileId, bool cellsRefs})>;
typedef $$CellsTableCreateCompanionBuilder = CellsCompanion Function({
  required String id,
  required String boardId,
  required int rowIndex,
  required int colIndex,
  required String label,
  Value<String?> speakText,
  Value<String?> symbolId,
  Value<String?> backgroundColor,
  Value<String> actionType,
  Value<String?> targetBoardId,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$CellsTableUpdateCompanionBuilder = CellsCompanion Function({
  Value<String> id,
  Value<String> boardId,
  Value<int> rowIndex,
  Value<int> colIndex,
  Value<String> label,
  Value<String?> speakText,
  Value<String?> symbolId,
  Value<String?> backgroundColor,
  Value<String> actionType,
  Value<String?> targetBoardId,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});

final class $$CellsTableReferences
    extends BaseReferences<_$AppDatabase, $CellsTable, Cell> {
  $$CellsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoardsTable _boardIdTable(_$AppDatabase db) =>
      db.boards.createAlias('cells__board_id__boards__id');

  $$BoardsTableProcessedTableManager get boardId {
    final $_column = $_itemColumn<String>('board_id')!;

    final manager = $$BoardsTableTableManager($_db, $_db.boards)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CellsTableFilterComposer extends Composer<_$AppDatabase, $CellsTable> {
  $$CellsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rowIndex => $composableBuilder(
      column: $table.rowIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colIndex => $composableBuilder(
      column: $table.colIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get speakText => $composableBuilder(
      column: $table.speakText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get symbolId => $composableBuilder(
      column: $table.symbolId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backgroundColor => $composableBuilder(
      column: $table.backgroundColor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actionType => $composableBuilder(
      column: $table.actionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetBoardId => $composableBuilder(
      column: $table.targetBoardId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));

  $$BoardsTableFilterComposer get boardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.boardId,
        referencedTable: $db.boards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BoardsTableFilterComposer(
              $db: $db,
              $table: $db.boards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CellsTableOrderingComposer
    extends Composer<_$AppDatabase, $CellsTable> {
  $$CellsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rowIndex => $composableBuilder(
      column: $table.rowIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colIndex => $composableBuilder(
      column: $table.colIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get speakText => $composableBuilder(
      column: $table.speakText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get symbolId => $composableBuilder(
      column: $table.symbolId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backgroundColor => $composableBuilder(
      column: $table.backgroundColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actionType => $composableBuilder(
      column: $table.actionType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetBoardId => $composableBuilder(
      column: $table.targetBoardId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));

  $$BoardsTableOrderingComposer get boardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.boardId,
        referencedTable: $db.boards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BoardsTableOrderingComposer(
              $db: $db,
              $table: $db.boards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CellsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CellsTable> {
  $$CellsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get rowIndex =>
      $composableBuilder(column: $table.rowIndex, builder: (column) => column);

  GeneratedColumn<int> get colIndex =>
      $composableBuilder(column: $table.colIndex, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get speakText =>
      $composableBuilder(column: $table.speakText, builder: (column) => column);

  GeneratedColumn<String> get symbolId =>
      $composableBuilder(column: $table.symbolId, builder: (column) => column);

  GeneratedColumn<String> get backgroundColor => $composableBuilder(
      column: $table.backgroundColor, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
      column: $table.actionType, builder: (column) => column);

  GeneratedColumn<String> get targetBoardId => $composableBuilder(
      column: $table.targetBoardId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  $$BoardsTableAnnotationComposer get boardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.boardId,
        referencedTable: $db.boards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BoardsTableAnnotationComposer(
              $db: $db,
              $table: $db.boards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CellsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CellsTable,
    Cell,
    $$CellsTableFilterComposer,
    $$CellsTableOrderingComposer,
    $$CellsTableAnnotationComposer,
    $$CellsTableCreateCompanionBuilder,
    $$CellsTableUpdateCompanionBuilder,
    (Cell, $$CellsTableReferences),
    Cell,
    PrefetchHooks Function({bool boardId})> {
  $$CellsTableTableManager(_$AppDatabase db, $CellsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CellsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CellsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CellsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> boardId = const Value.absent(),
            Value<int> rowIndex = const Value.absent(),
            Value<int> colIndex = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String?> speakText = const Value.absent(),
            Value<String?> symbolId = const Value.absent(),
            Value<String?> backgroundColor = const Value.absent(),
            Value<String> actionType = const Value.absent(),
            Value<String?> targetBoardId = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CellsCompanion(
            id: id,
            boardId: boardId,
            rowIndex: rowIndex,
            colIndex: colIndex,
            label: label,
            speakText: speakText,
            symbolId: symbolId,
            backgroundColor: backgroundColor,
            actionType: actionType,
            targetBoardId: targetBoardId,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String boardId,
            required int rowIndex,
            required int colIndex,
            required String label,
            Value<String?> speakText = const Value.absent(),
            Value<String?> symbolId = const Value.absent(),
            Value<String?> backgroundColor = const Value.absent(),
            Value<String> actionType = const Value.absent(),
            Value<String?> targetBoardId = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CellsCompanion.insert(
            id: id,
            boardId: boardId,
            rowIndex: rowIndex,
            colIndex: colIndex,
            label: label,
            speakText: speakText,
            symbolId: symbolId,
            backgroundColor: backgroundColor,
            actionType: actionType,
            targetBoardId: targetBoardId,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$CellsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({boardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (boardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.boardId,
                    referencedTable: $$CellsTableReferences._boardIdTable(db),
                    referencedColumn:
                        $$CellsTableReferences._boardIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CellsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CellsTable,
    Cell,
    $$CellsTableFilterComposer,
    $$CellsTableOrderingComposer,
    $$CellsTableAnnotationComposer,
    $$CellsTableCreateCompanionBuilder,
    $$CellsTableUpdateCompanionBuilder,
    (Cell, $$CellsTableReferences),
    Cell,
    PrefetchHooks Function({bool boardId})>;
typedef $$SymbolsTableCreateCompanionBuilder = SymbolsCompanion Function({
  required String id,
  Value<String> pack,
  Value<String?> packRef,
  required String label,
  Value<String?> category,
  Value<String> keywords,
  Value<String?> imageUrl,
  Value<String?> license,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});
typedef $$SymbolsTableUpdateCompanionBuilder = SymbolsCompanion Function({
  Value<String> id,
  Value<String> pack,
  Value<String?> packRef,
  Value<String> label,
  Value<String?> category,
  Value<String> keywords,
  Value<String?> imageUrl,
  Value<String?> license,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> dirty,
  Value<int> rowid,
});

class $$SymbolsTableFilterComposer
    extends Composer<_$AppDatabase, $SymbolsTable> {
  $$SymbolsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pack => $composableBuilder(
      column: $table.pack, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packRef => $composableBuilder(
      column: $table.packRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keywords => $composableBuilder(
      column: $table.keywords, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get license => $composableBuilder(
      column: $table.license, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnFilters(column));
}

class $$SymbolsTableOrderingComposer
    extends Composer<_$AppDatabase, $SymbolsTable> {
  $$SymbolsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pack => $composableBuilder(
      column: $table.pack, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packRef => $composableBuilder(
      column: $table.packRef, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keywords => $composableBuilder(
      column: $table.keywords, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get license => $composableBuilder(
      column: $table.license, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dirty => $composableBuilder(
      column: $table.dirty, builder: (column) => ColumnOrderings(column));
}

class $$SymbolsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SymbolsTable> {
  $$SymbolsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pack =>
      $composableBuilder(column: $table.pack, builder: (column) => column);

  GeneratedColumn<String> get packRef =>
      $composableBuilder(column: $table.packRef, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get keywords =>
      $composableBuilder(column: $table.keywords, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get license =>
      $composableBuilder(column: $table.license, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);
}

class $$SymbolsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SymbolsTable,
    Symbol,
    $$SymbolsTableFilterComposer,
    $$SymbolsTableOrderingComposer,
    $$SymbolsTableAnnotationComposer,
    $$SymbolsTableCreateCompanionBuilder,
    $$SymbolsTableUpdateCompanionBuilder,
    (Symbol, BaseReferences<_$AppDatabase, $SymbolsTable, Symbol>),
    Symbol,
    PrefetchHooks Function()> {
  $$SymbolsTableTableManager(_$AppDatabase db, $SymbolsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SymbolsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SymbolsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SymbolsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> pack = const Value.absent(),
            Value<String?> packRef = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String> keywords = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<String?> license = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SymbolsCompanion(
            id: id,
            pack: pack,
            packRef: packRef,
            label: label,
            category: category,
            keywords: keywords,
            imageUrl: imageUrl,
            license: license,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> pack = const Value.absent(),
            Value<String?> packRef = const Value.absent(),
            required String label,
            Value<String?> category = const Value.absent(),
            Value<String> keywords = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<String?> license = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> dirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SymbolsCompanion.insert(
            id: id,
            pack: pack,
            packRef: packRef,
            label: label,
            category: category,
            keywords: keywords,
            imageUrl: imageUrl,
            license: license,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            dirty: dirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SymbolsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SymbolsTable,
    Symbol,
    $$SymbolsTableFilterComposer,
    $$SymbolsTableOrderingComposer,
    $$SymbolsTableAnnotationComposer,
    $$SymbolsTableCreateCompanionBuilder,
    $$SymbolsTableUpdateCompanionBuilder,
    (Symbol, BaseReferences<_$AppDatabase, $SymbolsTable, Symbol>),
    Symbol,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$BoardsTableTableManager get boards =>
      $$BoardsTableTableManager(_db, _db.boards);
  $$CellsTableTableManager get cells =>
      $$CellsTableTableManager(_db, _db.cells);
  $$SymbolsTableTableManager get symbols =>
      $$SymbolsTableTableManager(_db, _db.symbols);
}
