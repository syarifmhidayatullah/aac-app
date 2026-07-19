import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/board_repository.dart';
import '../data/db.dart';
import '../state/communication_state.dart';
import 'account/account_screen.dart';
import 'editor/board_editor_screen.dart';
import 'widgets/board_grid.dart';
import 'widgets/cell_tile.dart';
import 'widgets/parental_gate.dart';
import 'widgets/sentence_strip.dart';

/// Layar utama: sentence strip di atas, grid papan simbol di bawah.
class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key});

  Future<void> _openEditor(BuildContext context) async {
    final allowed = await showParentalGate(context);
    if (!allowed || !context.mounted) return;

    final state = context.read<CommunicationState>();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => BoardEditorScreen(
        repository: context.read<BoardRepository>(),
        profileId: state.profileId,
        initialBoardId: state.current?.board.id,
      ),
    ));
    // Papan mungkin berubah selama mode edit.
    await state.reload();
  }

  Future<void> _openAccount(BuildContext context) async {
    final allowed = await showParentalGate(context);
    if (!allowed || !context.mounted) return;

    final state = context.read<CommunicationState>();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const AccountScreen(),
    ));
    // Sync bisa mengubah papan.
    await state.reload();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CommunicationState>();
    final board = state.current;

    return Scaffold(
      appBar: AppBar(
        leading: state.canGoBack
            ? IconButton(
                tooltip: 'Kembali',
                icon: const Icon(Icons.arrow_back),
                onPressed: state.goBack,
              )
            : null,
        title: Text(board?.board.name ?? 'AAC'),
        actions: [
          if (state.canGoBack)
            IconButton(
              tooltip: 'Ke papan utama',
              icon: const Icon(Icons.home_outlined),
              onPressed: state.goHome,
            ),
          IconButton(
            tooltip: 'Mode edit (orang tua)',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEditor(context),
          ),
          IconButton(
            tooltip: 'Akun & sinkronisasi (orang tua)',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _openAccount(context),
          ),
        ],
      ),
      body: state.loading || board == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SentenceStrip(),
                Expanded(
                  child: _BoardGrid(
                    board: board,
                    onCellTap: state.tapCell,
                  ),
                ),
              ],
            ),
    );
  }
}

class _BoardGrid extends StatelessWidget {
  const _BoardGrid({required this.board, required this.onCellTap});

  final BoardWithCells board;
  final Future<void> Function(Cell) onCellTap;

  @override
  Widget build(BuildContext context) {
    final rows = board.board.gridRows;
    final cols = board.board.gridCols;
    final cells = board.cells;

    final byPosition = <(int, int), Cell>{
      for (final c in cells) (c.rowIndex, c.colIndex): c,
    };

    return Padding(
      padding: const EdgeInsets.all(8),
      child: BoardGridLayout(
        rows: rows,
        cols: cols,
        itemBuilder: (context, row, col) {
          final cell = byPosition[(row, col)];
          if (cell == null) return const SizedBox.shrink();
          return CellTile(
            cell: cell,
            symbol:
                cell.symbolId == null ? null : board.symbols[cell.symbolId],
            onTap: () => onCellTap(cell),
          );
        },
      ),
    );
  }
}
