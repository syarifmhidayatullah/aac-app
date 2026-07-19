import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aac_app/data/board_repository.dart';
import 'package:aac_app/data/db.dart';
import 'package:aac_app/data/seed.dart';
import 'package:aac_app/services/api_client.dart';
import 'package:aac_app/services/sync_service.dart';
import 'package:aac_app/state/account_state.dart';

/// ApiClient palsu: merekam push & mengembalikan pull yang disetel test.
class FakeApi extends ApiClient {
  FakeApi() : super(baseUrl: 'http://test');

  final serverTime = DateTime.utc(2026, 7, 7, 12);
  SyncPayload pullResult = SyncPayload();
  SyncPayload? lastPushed;
  DateTime? lastSince;
  int uploads = 0;
  Object? failWith;

  @override
  Future<SyncPayload> syncPull({DateTime? since}) async {
    if (failWith != null) throw failWith!;
    lastSince = since;
    return SyncPayload(
      serverTime: serverTime,
      profiles: pullResult.profiles,
      boards: pullResult.boards,
      cells: pullResult.cells,
      symbols: pullResult.symbols,
    );
  }

  @override
  Future<DateTime> syncPush(SyncPayload payload) async {
    if (failWith != null) throw failWith!;
    lastPushed = payload;
    return serverTime;
  }

  @override
  Future<String> uploadImage(Uint8List bytes, String filename) async {
    uploads++;
    return 'http://test/uploads/foto$uploads.png';
  }

  @override
  Future<AuthResult> login(String email, String password) async {
    if (failWith != null) throw failWith!;
    return AuthResult(token: 'jwt-token', email: email, displayName: 'Budi');
  }
}

String _ts(DateTime t) => t.toUtc().toIso8601String();

void main() {
  late AppDatabase db;
  late FakeApi api;
  late SyncService sync;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    await seedIfEmpty(db);
    api = FakeApi();
    sync = SyncService(db: db, api: api);
  });

  tearDown(() async {
    await db.close();
  });

  test('firstSync: server kosong → push seluruh seed lokal', () async {
    final result = await sync.firstSync();

    expect(result.newActiveProfileId, isNull,
        reason: 'data lokal dipertahankan');
    final pushed = api.lastPushed!;
    expect(pushed.profiles.length, 1);
    expect(pushed.boards.length, 3);
    expect(pushed.cells.length, 26 + 12 + 6);
    expect(pushed.symbols.length, 173);

    // Semua bersih setelah push.
    final dirtyCells = await (db.select(db.cells)
          ..where((c) => c.dirty.equals(true)))
        .get();
    expect(dirtyCells, isEmpty);
  });

  test('firstSync: server punya data → lokal diganti snapshot server',
      () async {
    final now = DateTime.now().toUtc();
    api.pullResult = SyncPayload(
      profiles: [
        {'id': 'p-server', 'name': 'Dari Server', 'settings': {},
         'updated_at': _ts(now)},
      ],
      boards: [
        {'id': 'b-server', 'profile_id': 'p-server', 'name': 'Utama',
         'grid_rows': 2, 'grid_cols': 2, 'is_root': true,
         'updated_at': _ts(now)},
      ],
      cells: [
        {'id': 'c-server', 'board_id': 'b-server', 'row_index': 0,
         'col_index': 0, 'label': 'Halo', 'action_type': 'speak',
         'updated_at': _ts(now)},
      ],
    );

    final result = await sync.firstSync();
    expect(result.newActiveProfileId, 'p-server');

    final profiles = await db.select(db.profiles).get();
    expect(profiles.map((p) => p.id), ['p-server']);
    final repo = BoardRepository(db);
    final root = await repo.getRootBoard('p-server');
    expect(root.cells.single.label, 'Halo');
    expect(root.cells.single.dirty, isFalse);
  });

  test('sync: hanya baris dirty yang di-push, lalu ditandai bersih',
      () async {
    await sync.firstSync(); // semuanya bersih

    final repo = BoardRepository(db);
    final root =
        await repo.getRootBoard((await db.select(db.profiles).get()).single.id);
    await repo.upsertCell(
      boardId: root.board.id,
      rowIndex: 4,
      colIndex: 3,
      label: 'Sekolah',
    );

    api.lastPushed = null;
    final since = DateTime.utc(2026, 7, 7, 11);
    await sync.sync(since: since);

    expect(api.lastSince, since);
    final pushed = api.lastPushed!;
    expect(pushed.profiles, isEmpty);
    expect(pushed.cells.single['label'], 'Sekolah');

    final dirty = await (db.select(db.cells)
          ..where((c) => c.dirty.equals(true)))
        .get();
    expect(dirty, isEmpty);
  });

  test('sync: pull menerapkan perubahan & tombstone dari server',
      () async {
    await sync.firstSync();
    final repo = BoardRepository(db);
    final profileId = (await db.select(db.profiles).get()).single.id;
    final root = await repo.getRootBoard(profileId);
    final target = root.cells.first;

    final now = DateTime.now().toUtc();
    api.pullResult = SyncPayload(cells: [
      {
        'id': target.id, 'board_id': target.boardId,
        'row_index': target.rowIndex, 'col_index': target.colIndex,
        'label': target.label, 'action_type': 'speak',
        'updated_at': _ts(now), 'deleted_at': _ts(now),
      },
    ]);

    await sync.sync(since: DateTime.utc(2026, 7, 7, 11));

    final after = await repo.getRootBoard(profileId);
    expect(after.cells.map((c) => c.id), isNot(contains(target.id)),
        reason: 'tombstone server menghapus sel lokal');
  });

  test('sync: foto custom (data URI) di-upload dan imageUrl ditukar URL server',
      () async {
    await sync.firstSync();

    final repo = BoardRepository(db);
    final dataUri = 'data:image/png;base64,${base64Encode([1, 2, 3])}';
    final symbol =
        await repo.createSymbol(label: 'Boneka', imageUrl: dataUri);

    await sync.sync();

    final updated = await (db.select(db.symbols)
          ..where((s) => s.id.equals(symbol.id)))
        .getSingle();
    expect(updated.imageUrl, 'http://test/uploads/foto1.png');
    expect(updated.dirty, isFalse, reason: 'ikut ter-push setelah upload');
    final pushedSymbol = api.lastPushed!.symbols
        .singleWhere((s) => s['id'] == symbol.id);
    expect(pushedSymbol['image_url'], 'http://test/uploads/foto1.png');
  });

  test('simbol Mulberry punya id deterministik antar perangkat', () {
    expect(mulberrySymbolId('eat'), mulberrySymbolId('eat'));
    expect(mulberrySymbolId('eat'), isNot(mulberrySymbolId('drink')));
  });

  group('AccountState', () {
    test('signIn menyimpan sesi + sync pertama; logout mempertahankan data',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final account = AccountState(db: db, prefs: prefs, api: api)..init();

      final newProfile =
          await account.signIn(email: 'budi@example.com', password: 'rahasia1');
      expect(newProfile, isNull, reason: 'server kosong → data lokal dipush');
      expect(account.loggedIn, isTrue);
      expect(account.email, 'budi@example.com');
      expect(account.lastSync, api.serverTime);
      expect(prefs.getString('token'), 'jwt-token');

      await account.logout();
      expect(account.loggedIn, isFalse);
      expect(prefs.getString('token'), isNull);
      // Data lokal tidak dihapus saat logout.
      expect(await db.select(db.profiles).get(), isNotEmpty);
    });

    test('syncNow gagal → lastError terisi, tidak melempar', () async {
      SharedPreferences.setMockInitialValues({'token': 'jwt-token'});
      final prefs = await SharedPreferences.getInstance();
      final account = AccountState(db: db, prefs: prefs, api: api)..init();
      expect(account.loggedIn, isTrue);

      api.failWith = ApiException(401, 'invalid_credentials', 'nope');
      final ok = await account.syncNow();
      expect(ok, isFalse);
      expect(account.lastError, isNotNull);
    });
  });
}
