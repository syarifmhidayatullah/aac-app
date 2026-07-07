import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/board_repository.dart';
import '../data/db.dart';
import '../state/communication_state.dart';
import 'widgets/cell_tile.dart';
import 'widgets/sentence_strip.dart';

/// Layar utama: sentence strip di atas, grid papan simbol di bawah.
class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key});

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
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: rows * cols,
        itemBuilder: (context, index) {
          final cell = byPosition[(index ~/ cols, index % cols)];
          if (cell == null) return const SizedBox.shrink();
          return CellTile(cell: cell, onTap: () => onCellTap(cell));
        },
      ),
    );
  }
}
