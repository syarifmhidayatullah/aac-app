import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/db.dart';
import 'api_client.dart';
import 'image_store.dart';

/// Sinkronisasi dua arah dengan backend.
///
/// Model: semua tabel data lokal punya kolom `dirty` (perubahan yang
/// belum di-push) dan server menyelesaikan konflik last-push-wins.
/// Tombstone (deleted_at) ikut dua arah supaya penghapusan menyebar.
class SyncService {
  SyncService({
    required AppDatabase db,
    required this.api,
    ImageStore? imageStore,
  })  : _db = db,
        _imageStore = imageStore;

  final AppDatabase _db;
  final ApiClient api;
  final ImageStore? _imageStore;

  /// Sinkronisasi pertama setelah login/registrasi.
  ///
  /// - Server sudah punya data → data lokal (seed yang belum pernah
  ///   di-push) DIBUANG dan diganti data server; mengembalikan id
  ///   profile aktif baru.
  /// - Server kosong → seluruh data lokal di-push (perangkat pertama).
  Future<({String? newActiveProfileId, DateTime serverTime})>
      firstSync() async {
    final pulled = await api.syncPull();

    if (pulled.profiles.isNotEmpty) {
      await _replaceLocal(pulled);
      final active = pulled.profiles.firstWhere(
        (p) => p['deleted_at'] == null,
        orElse: () => pulled.profiles.first,
      )['id'] as String;
      return (newActiveProfileId: active, serverTime: pulled.serverTime!);
    }

    final pushedAt = await _pushDirty();
    return (
      newActiveProfileId: null,
      serverTime: pushedAt ?? pulled.serverTime!,
    );
  }

  /// Sinkronisasi rutin: upload foto → push perubahan lokal → pull
  /// perubahan server sejak [since]. Mengembalikan server_time baru.
  Future<DateTime> sync({DateTime? since}) async {
    await _uploadPendingImages();
    await _pushDirty();
    final pulled = await api.syncPull(since: since);
    await _applyPulled(pulled);
    return pulled.serverTime!;
  }

  // ------------------------------------------------------------- push

  /// Upload foto custom yang masih lokal (path relatif / data URI) dan
  /// tukar imageUrl-nya dengan URL server, supaya perangkat lain bisa
  /// merendernya. Baris tetap dirty sehingga ikut push berikutnya.
  Future<void> _uploadPendingImages() async {
    final pending = await (_db.select(_db.symbols)
          ..where((s) =>
              s.dirty.equals(true) &
              s.imageUrl.isNotNull() &
              s.imageUrl.like('http%').not() &
              s.imageUrl.like('assets/%').not()))
        .get();

    for (final symbol in pending) {
      final url = symbol.imageUrl!;
      List<int>? bytes;
      String filename = 'foto.jpg';
      if (url.startsWith('data:')) {
        final comma = url.indexOf(',');
        if (comma != -1) bytes = base64Decode(url.substring(comma + 1));
      } else if (_imageStore != null) {
        final file = _imageStore.resolve(url);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
          filename = url.split('/').last;
        }
      }
      if (bytes == null) continue; // file hilang — biarkan apa adanya

      final serverUrl =
          await api.uploadImage(Uint8List.fromList(bytes), filename);
      await (_db.update(_db.symbols)..where((s) => s.id.equals(symbol.id)))
          .write(SymbolsCompanion(imageUrl: Value(serverUrl)));
    }
  }

  /// Push semua baris dirty; mengembalikan server_time (null kalau
  /// tidak ada yang perlu di-push).
  Future<DateTime?> _pushDirty() async {
    final profiles = await (_db.select(_db.profiles)
          ..where((t) => t.dirty.equals(true)))
        .get();
    final boards = await (_db.select(_db.boards)
          ..where((t) => t.dirty.equals(true)))
        .get();
    final cells = await (_db.select(_db.cells)
          ..where((t) => t.dirty.equals(true)))
        .get();
    final symbols = await (_db.select(_db.symbols)
          ..where((t) => t.dirty.equals(true)))
        .get();

    final payload = SyncPayload(
      profiles: [
        for (final p in profiles)
          {
            'id': p.id,
            'name': p.name,
            'settings': jsonDecode(p.settings),
            'deleted_at': _ts(p.deletedAt),
          }
      ],
      boards: [
        for (final b in boards)
          {
            'id': b.id,
            'profile_id': b.profileId,
            'name': b.name,
            'grid_rows': b.gridRows,
            'grid_cols': b.gridCols,
            'is_root': b.isRoot,
            'deleted_at': _ts(b.deletedAt),
          }
      ],
      cells: [
        for (final c in cells)
          {
            'id': c.id,
            'board_id': c.boardId,
            'row_index': c.rowIndex,
            'col_index': c.colIndex,
            'label': c.label,
            'speak_text': c.speakText,
            'symbol_id': c.symbolId,
            'background_color': c.backgroundColor,
            'action_type': c.actionType,
            'target_board_id': c.targetBoardId,
            'deleted_at': _ts(c.deletedAt),
          }
      ],
      symbols: [
        for (final s in symbols)
          {
            'id': s.id,
            'pack': s.pack,
            'pack_ref': s.packRef,
            'label': s.label,
            'keywords': jsonDecode(s.keywords),
            'image_url': s.imageUrl,
            'license': s.license,
            'deleted_at': _ts(s.deletedAt),
          }
      ],
    );
    if (payload.isEmpty) return null;

    final serverTime = await api.syncPush(payload);

    await _db.transaction(() async {
      await _markClean(_db.profiles, [for (final p in profiles) p.id]);
      await _markClean(_db.boards, [for (final b in boards) b.id]);
      await _markClean(_db.cells, [for (final c in cells) c.id]);
      await _markClean(_db.symbols, [for (final s in symbols) s.id]);
    });
    return serverTime;
  }

  Future<void> _markClean(TableInfo table, List<String> ids) async {
    if (ids.isEmpty) return;
    await _db.customUpdate(
      'UPDATE ${table.actualTableName} SET dirty = 0 WHERE id IN '
      '(${List.filled(ids.length, '?').join(',')})',
      variables: [for (final id in ids) Variable.withString(id)],
      updates: {table},
    );
  }

  // ------------------------------------------------------------- pull

  /// Buang seluruh data lokal, ganti dengan snapshot server.
  Future<void> _replaceLocal(SyncPayload pulled) async {
    await _db.transaction(() async {
      await _db.delete(_db.cells).go();
      await _db.delete(_db.boards).go();
      await _db.delete(_db.symbols).go();
      await _db.delete(_db.profiles).go();
      await _upsertPulled(pulled);
    });
  }

  Future<void> _applyPulled(SyncPayload pulled) async {
    if (pulled.isEmpty) return;
    await _db.transaction(() => _upsertPulled(pulled));
  }

  /// Upsert baris dari server (urutan FK: profiles → symbols → boards
  /// → cells), semuanya bersih (dirty=false). Tombstone ikut tersimpan
  /// supaya penghapusan menyebar; query pembaca memfilter deleted_at.
  Future<void> _upsertPulled(SyncPayload pulled) async {
    for (final p in pulled.profiles) {
      await _db.into(_db.profiles).insertOnConflictUpdate(ProfilesCompanion(
            id: Value(p['id'] as String),
            name: Value(p['name'] as String),
            settings: Value(jsonEncode(p['settings'] ?? {})),
            updatedAt: Value(_parseTs(p['updated_at'])!),
            deletedAt: Value(_parseTs(p['deleted_at'])),
            dirty: const Value(false),
          ));
    }
    for (final s in pulled.symbols) {
      await _db.into(_db.symbols).insertOnConflictUpdate(SymbolsCompanion(
            id: Value(s['id'] as String),
            pack: Value(s['pack'] as String? ?? 'custom'),
            packRef: Value(s['pack_ref'] as String?),
            label: Value(s['label'] as String),
            keywords: Value(jsonEncode(s['keywords'] ?? [])),
            imageUrl: Value(s['image_url'] as String?),
            license: Value(s['license'] as String?),
            updatedAt: Value(_parseTs(s['updated_at'])!),
            deletedAt: Value(_parseTs(s['deleted_at'])),
            dirty: const Value(false),
          ));
    }
    for (final b in pulled.boards) {
      await _db.into(_db.boards).insertOnConflictUpdate(BoardsCompanion(
            id: Value(b['id'] as String),
            profileId: Value(b['profile_id'] as String),
            name: Value(b['name'] as String),
            gridRows: Value(b['grid_rows'] as int),
            gridCols: Value(b['grid_cols'] as int),
            isRoot: Value(b['is_root'] as bool),
            updatedAt: Value(_parseTs(b['updated_at'])!),
            deletedAt: Value(_parseTs(b['deleted_at'])),
            dirty: const Value(false),
          ));
    }
    for (final c in pulled.cells) {
      await _db.into(_db.cells).insertOnConflictUpdate(CellsCompanion(
            id: Value(c['id'] as String),
            boardId: Value(c['board_id'] as String),
            rowIndex: Value(c['row_index'] as int),
            colIndex: Value(c['col_index'] as int),
            label: Value(c['label'] as String),
            speakText: Value(c['speak_text'] as String?),
            symbolId: Value(c['symbol_id'] as String?),
            backgroundColor: Value(c['background_color'] as String?),
            actionType: Value(c['action_type'] as String? ?? 'speak'),
            targetBoardId: Value(c['target_board_id'] as String?),
            updatedAt: Value(_parseTs(c['updated_at'])!),
            deletedAt: Value(_parseTs(c['deleted_at'])),
            dirty: const Value(false),
          ));
    }
  }

  static String? _ts(DateTime? t) => t?.toUtc().toIso8601String();

  static DateTime? _parseTs(dynamic v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();
}
