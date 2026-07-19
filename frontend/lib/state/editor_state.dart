import 'package:flutter/foundation.dart';

import '../data/board_repository.dart';
import '../data/db.dart';

/// State mode edit caregiver: papan yang sedang diedit + daftar papan
/// milik profile (untuk pindah papan & target navigasi).
class EditorState extends ChangeNotifier {
  EditorState({
    required BoardRepository repository,
    required String profileId,
  })  : _repository = repository,
        _profileId = profileId;

  final BoardRepository _repository;
  final String _profileId;

  BoardWithCells? _current;
  List<Board> _boards = [];
  bool _loading = true;

  bool get loading => _loading;
  BoardWithCells? get current => _current;
  List<Board> get boards => List.unmodifiable(_boards);
  String get profileId => _profileId;

  Cell? cellAt(int row, int col) {
    final cells = _current?.cells;
    if (cells == null) return null;
    for (final c in cells) {
      if (c.rowIndex == row && c.colIndex == col) return c;
    }
    return null;
  }

  /// Muat papan [boardId], atau papan utama kalau null.
  Future<void> load([String? boardId]) async {
    _loading = true;
    notifyListeners();
    _boards = await _repository.listBoards(_profileId);
    _current = boardId == null
        ? await _repository.getRootBoard(_profileId)
        : await _repository.getBoard(boardId);
    _loading = false;
    notifyListeners();
  }

  Future<void> _refresh() async {
    final id = _current?.board.id;
    if (id == null) return;
    _boards = await _repository.listBoards(_profileId);
    _current = await _repository.getBoard(id);
    notifyListeners();
  }

  Future<void> switchBoard(String boardId) => load(boardId);

  Future<void> saveCell({
    String? id,
    required int rowIndex,
    required int colIndex,
    required String label,
    String? speakText,
    String? symbolId,
    String? backgroundColor,
    String actionType = 'speak',
    String? targetBoardId,
  }) async {
    final boardId = _current?.board.id;
    if (boardId == null) return;
    await _repository.upsertCell(
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
    );
    await _refresh();
  }

  Future<void> removeCell(String cellId) async {
    await _repository.deleteCell(cellId);
    await _refresh();
  }

  Future<void> updateBoardSettings({
    String? name,
    int? rows,
    int? cols,
  }) async {
    final boardId = _current?.board.id;
    if (boardId == null) return;
    await _repository.updateBoard(boardId, name: name, rows: rows, cols: cols);
    await _refresh();
  }

  /// Buat papan baru; mengembalikan papan tersebut (mis. sebagai target
  /// navigasi). Tidak berpindah papan.
  Future<Board> createBoard(String name, {int rows = 3, int cols = 4}) async {
    final board = await _repository.createBoard(
      profileId: _profileId,
      name: name,
      rows: rows,
      cols: cols,
    );
    _boards = await _repository.listBoards(_profileId);
    notifyListeners();
    return board;
  }
}
