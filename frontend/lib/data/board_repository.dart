import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'db.dart';

const _uuid = Uuid();

/// Papan beserta sel aktifnya, siap dirender.
class BoardWithCells {
  const BoardWithCells(this.board, this.cells, {this.symbols = const {}});

  final Board board;
  final List<Cell> cells;

  /// Simbol yang direferensikan [cells], di-key oleh id — untuk
  /// merender gambar sel tanpa query tambahan.
  final Map<String, Symbol> symbols;
}

class BoardRepository {
  BoardRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------- reads

  Future<BoardWithCells> getRootBoard(String profileId) async {
    final board = await (_db.select(_db.boards)
          ..where((b) =>
              b.profileId.equals(profileId) &
              b.isRoot.equals(true) &
              b.deletedAt.isNull()))
        .getSingle();
    return _withCells(board);
  }

  Future<BoardWithCells?> getBoard(String boardId) async {
    final board = await (_db.select(_db.boards)
          ..where((b) => b.id.equals(boardId) & b.deletedAt.isNull()))
        .getSingleOrNull();
    if (board == null) return null;
    return _withCells(board);
  }

  Future<Profile> getProfile(String profileId) {
    return (_db.select(_db.profiles)
          ..where((p) => p.id.equals(profileId) & p.deletedAt.isNull()))
        .getSingle();
  }

  /// Merge [changes] ke settings JSON profile (mis. tts_rate/tts_pitch)
  /// dan tandai dirty supaya ikut sync.
  Future<void> updateProfileSettings(
      String profileId, Map<String, dynamic> changes) async {
    final profile = await getProfile(profileId);
    final settings =
        (jsonDecode(profile.settings) as Map<String, dynamic>?) ?? {};
    settings.addAll(changes);
    await (_db.update(_db.profiles)..where((p) => p.id.equals(profileId)))
        .write(ProfilesCompanion(
      settings: Value(jsonEncode(settings)),
      updatedAt: Value(DateTime.now()),
      dirty: const Value(true),
    ));
  }

  Future<bool> profileExists(String profileId) async {
    final row = await (_db.select(_db.profiles)
          ..where((p) => p.id.equals(profileId) & p.deletedAt.isNull()))
        .getSingleOrNull();
    return row != null;
  }

  /// Semua papan aktif milik profile, papan utama dulu lalu alfabetis.
  Future<List<Board>> listBoards(String profileId) {
    return (_db.select(_db.boards)
          ..where(
              (b) => b.profileId.equals(profileId) & b.deletedAt.isNull())
          ..orderBy([
            (b) => OrderingTerm(
                expression: b.isRoot, mode: OrderingMode.desc),
            (b) => OrderingTerm(expression: b.name),
          ]))
        .get();
  }

  Future<BoardWithCells> _withCells(Board board) async {
    final cells = await (_db.select(_db.cells)
          ..where((c) => c.boardId.equals(board.id) & c.deletedAt.isNull())
          ..orderBy([
            (c) => OrderingTerm(expression: c.rowIndex),
            (c) => OrderingTerm(expression: c.colIndex),
          ]))
        .get();

    final symbolIds = cells
        .map((c) => c.symbolId)
        .whereType<String>()
        .toSet()
        .toList();
    var symbols = const <String, Symbol>{};
    if (symbolIds.isNotEmpty) {
      final rows = await (_db.select(_db.symbols)
            ..where((s) => s.id.isIn(symbolIds) & s.deletedAt.isNull()))
          .get();
      symbols = {for (final s in rows) s.id: s};
    }
    return BoardWithCells(board, cells, symbols: symbols);
  }

  // --------------------------------------------------------------- boards

  Future<Board> createBoard({
    required String profileId,
    required String name,
    int rows = 3,
    int cols = 4,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.boards).insert(BoardsCompanion.insert(
          id: id,
          profileId: profileId,
          name: name,
          gridRows: Value(rows),
          gridCols: Value(cols),
        ));
    return (_db.select(_db.boards)..where((b) => b.id.equals(id)))
        .getSingle();
  }

  /// Ubah nama dan/atau ukuran grid. Sel di luar grid baru TIDAK
  /// dihapus — hanya tak dirender; muncul lagi kalau grid diperbesar.
  Future<void> updateBoard(
    String boardId, {
    String? name,
    int? rows,
    int? cols,
  }) async {
    await (_db.update(_db.boards)..where((b) => b.id.equals(boardId)))
        .write(BoardsCompanion(
      name: name == null ? const Value.absent() : Value(name),
      gridRows: rows == null ? const Value.absent() : Value(rows),
      gridCols: cols == null ? const Value.absent() : Value(cols),
      updatedAt: Value(DateTime.now()),
      dirty: const Value(true),
    ));
  }

  // ---------------------------------------------------------------- cells

  /// Insert (id null) atau update sel. Mengembalikan sel tersimpan.
  Future<Cell> upsertCell({
    String? id,
    required String boardId,
    required int rowIndex,
    required int colIndex,
    required String label,
    String? speakText,
    String? symbolId,
    String? backgroundColor,
    String actionType = 'speak',
    String? targetBoardId,
  }) async {
    final cellId = id ?? _uuid.v4();
    await _db.into(_db.cells).insertOnConflictUpdate(CellsCompanion(
          id: Value(cellId),
          boardId: Value(boardId),
          rowIndex: Value(rowIndex),
          colIndex: Value(colIndex),
          label: Value(label),
          speakText: Value(speakText),
          symbolId: Value(symbolId),
          backgroundColor: Value(backgroundColor),
          actionType: Value(actionType),
          targetBoardId: Value(targetBoardId),
          updatedAt: Value(DateTime.now()),
          deletedAt: const Value(null),
          dirty: const Value(true),
        ));
    return (_db.select(_db.cells)..where((c) => c.id.equals(cellId)))
        .getSingle();
  }

  /// Soft delete — baris tetap ada sebagai tombstone untuk sync.
  Future<void> deleteCell(String cellId) async {
    await (_db.update(_db.cells)..where((c) => c.id.equals(cellId)))
        .write(CellsCompanion(
      deletedAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
      dirty: const Value(true),
    ));
  }

  // -------------------------------------------------------------- symbols

  /// Cari simbol aktif berdasarkan label/keywords (case-insensitive).
  /// Query kosong mengembalikan semuanya (untuk browsing pustaka).
  Future<List<Symbol>> searchSymbols(String query, {int limit = 150}) {
    final select = _db.select(_db.symbols)
      ..where((s) => s.deletedAt.isNull());
    final q = query.trim();
    if (q.isNotEmpty) {
      final pattern = '%${q.toLowerCase()}%';
      select.where((s) =>
          s.label.lower().like(pattern) | s.keywords.lower().like(pattern));
    }
    select
      ..orderBy([(s) => OrderingTerm(expression: s.label)])
      ..limit(limit);
    return select.get();
  }

  /// Daftarkan simbol custom (foto pengguna).
  Future<Symbol> createSymbol({
    required String label,
    required String imageUrl,
    String pack = 'custom',
    List<String> keywords = const [],
    String? license,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.symbols).insert(SymbolsCompanion.insert(
          id: id,
          label: label,
          pack: Value(pack),
          keywords: Value(_encodeKeywords(keywords)),
          imageUrl: Value(imageUrl),
          license: Value(license),
        ));
    return (_db.select(_db.symbols)..where((s) => s.id.equals(id)))
        .getSingle();
  }

  String _encodeKeywords(List<String> keywords) =>
      '[${keywords.map((k) => '"${k.replaceAll('"', r'\"')}"').join(',')}]';
}
