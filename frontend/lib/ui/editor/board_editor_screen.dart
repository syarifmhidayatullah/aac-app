import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/board_repository.dart';
import '../../state/account_state.dart';
import '../../state/editor_state.dart';
import '../widgets/board_grid.dart';
import '../widgets/cell_tile.dart';
import 'cell_editor_sheet.dart';
import 'voice_settings_dialog.dart';

const _maxRows = 8;
const _maxCols = 10;

/// Layar mode edit caregiver: grid papan dengan slot kosong yang bisa
/// diisi, tap sel untuk mengubah, plus pengaturan papan & pindah papan.
class BoardEditorScreen extends StatelessWidget {
  const BoardEditorScreen({
    super.key,
    required this.repository,
    required this.profileId,
    this.initialBoardId,
  });

  final BoardRepository repository;
  final String profileId;
  final String? initialBoardId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorState(
        repository: repository,
        profileId: profileId,
      )..load(initialBoardId),
      child: const _EditorScaffold(),
    );
  }
}

class _EditorScaffold extends StatelessWidget {
  const _EditorScaffold();

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorState>();
    final board = editor.current;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode edit'),
        actions: [
          if (board != null) ...[
            IconButton(
              tooltip: 'Pengaturan suara',
              icon: const Icon(Icons.record_voice_over_outlined),
              onPressed: () => showVoiceSettings(
                  context, context.read<EditorState>().profileId),
            ),
            IconButton(
              tooltip: 'Bagikan papan (kode)',
              icon: const Icon(Icons.ios_share),
              onPressed: () => _shareBoard(context, board.board.id),
            ),
            IconButton(
              tooltip: 'Pengaturan papan',
              icon: const Icon(Icons.grid_view_outlined),
              onPressed: () => _showBoardSettings(context, editor),
            ),
            IconButton(
              tooltip: 'Selesai',
              icon: const Icon(Icons.check),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ],
        bottom: board == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.dashboard_customize_outlined,
                          size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: board.board.id,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          items: [
                            for (final b in editor.boards)
                              DropdownMenuItem(
                                value: b.id,
                                child: Text(
                                  b.isRoot ? '${b.name} (utama)' : b.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (id) {
                            if (id != null) editor.switchBoard(id);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      body: editor.loading || board == null
          ? const Center(child: CircularProgressIndicator())
          : _EditorGrid(editor: editor),
    );
  }
}

class _EditorGrid extends StatelessWidget {
  const _EditorGrid({required this.editor});

  final EditorState editor;

  @override
  Widget build(BuildContext context) {
    final board = editor.current!;
    final rows = board.board.gridRows;
    final cols = board.board.gridCols;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: BoardGridLayout(
        rows: rows,
        cols: cols,
        itemBuilder: (context, row, col) {
          final cell = editor.cellAt(row, col);

          if (cell == null) {
            return _EmptySlot(
              onTap: () => showCellEditor(
                context,
                editor: editor,
                rowIndex: row,
                colIndex: col,
              ),
            );
          }
          return CellTile(
            cell: cell,
            symbol: cell.symbolId == null
                ? null
                : board.symbols[cell.symbolId],
            onTap: () => showCellEditor(
              context,
              editor: editor,
              rowIndex: row,
              colIndex: col,
              cell: cell,
            ),
          );
        },
      ),
    );
  }
}

/// Slot kosong di grid: garis putus-putus + ikon tambah.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Center(child: Icon(Icons.add, color: color, size: 32)),
      ),
    );
  }
}

/// Bagikan papan: butuh login; sinkronkan dulu supaya papan ada di
/// server, lalu tampilkan kode yang bisa dibacakan/disalin.
Future<void> _shareBoard(BuildContext context, String boardId) async {
  final account = context.read<AccountState>();
  final messenger = ScaffoldMessenger.of(context);
  if (!account.loggedIn) {
    messenger.showSnackBar(const SnackBar(
        content:
            Text('Masuk dulu lewat menu Akun untuk berbagi papan.')));
    return;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  ShareCodeResult result;
  try {
    final share = await account.shareBoard(boardId);
    result = (code: share.code, expiresAt: share.expiresAt, error: null);
  } catch (e) {
    result = (code: null, expiresAt: null, error: AccountState.friendlyError(e));
  }
  if (!context.mounted) return;
  Navigator.of(context).pop(); // tutup loading

  final code = result.code;
  if (code == null) {
    messenger.showSnackBar(SnackBar(content: Text(result.error!)));
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Kode berbagi papan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            code,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Berlaku 7 hari. Akun lain memasukkan kode ini lewat '
            'menu Akun → "Impor papan dengan kode".',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Selesai'),
        ),
      ],
    ),
  );
}

typedef ShareCodeResult = ({String? code, DateTime? expiresAt, String? error});

Future<void> _showBoardSettings(
    BuildContext context, EditorState editor) async {
  final board = editor.current!.board;
  final nameController = TextEditingController(text: board.name);
  var rows = board.gridRows;
  var cols = board.gridCols;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Pengaturan papan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama papan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _Stepper(
              label: 'Baris',
              value: rows,
              max: _maxRows,
              onChanged: (v) => setState(() => rows = v),
            ),
            _Stepper(
              label: 'Kolom',
              value: cols,
              max: _maxCols,
              onChanged: (v) => setState(() => cols = v),
            ),
            const SizedBox(height: 8),
            Text(
              'Sel di luar grid tidak dihapus — muncul lagi kalau '
              'grid diperbesar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              await editor.updateBoardSettings(
                name: name.isEmpty ? null : name,
                rows: rows,
                cols: cols,
              );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
  nameController.dispose();
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text('$value', textAlign: TextAlign.center),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
