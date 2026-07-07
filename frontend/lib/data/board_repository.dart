import 'package:drift/drift.dart';

import 'db.dart';

/// Papan beserta sel aktifnya, siap dirender.
class BoardWithCells {
  const BoardWithCells(this.board, this.cells);

  final Board board;
  final List<Cell> cells;
}

class BoardRepository {
  BoardRepository(this._db);

  final AppDatabase _db;

  Future<BoardWithCells> getRootBoard(String profileId) async {
    final board = await (_db.select(_db.boards)
          ..where((b) =>
              b.profileId.equals(profileId) &
              b.isRoot.equals(true) &
              b.deletedAt.isNull()))
        .getSingle();
    return BoardWithCells(board, await _activeCells(board.id));
  }

  Future<BoardWithCells?> getBoard(String boardId) async {
    final board = await (_db.select(_db.boards)
          ..where((b) => b.id.equals(boardId) & b.deletedAt.isNull()))
        .getSingleOrNull();
    if (board == null) return null;
    return BoardWithCells(board, await _activeCells(board.id));
  }

  Future<List<Cell>> _activeCells(String boardId) {
    return (_db.select(_db.cells)
          ..where((c) => c.boardId.equals(boardId) & c.deletedAt.isNull())
          ..orderBy([
            (c) => OrderingTerm(expression: c.rowIndex),
            (c) => OrderingTerm(expression: c.colIndex),
          ]))
        .get();
  }
}
