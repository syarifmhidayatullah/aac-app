import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db.dart';
import '../../data/seed.dart';
import '../../state/editor_state.dart';
import '../widgets/cell_tile.dart' show colorFromHex;
import '../widgets/symbol_image.dart';
import 'symbol_picker.dart';

/// Pilihan warna latar sel — konvensi Fitzgerald key (lihat seed.dart).
const _colorChoices = <(String, String)>[
  ('Kuning — kata ganti', colorPronoun),
  ('Hijau — kata kerja', colorVerb),
  ('Biru — kata sifat', colorDescriptor),
  ('Pink — sosial', colorSocial),
  ('Oranye — kata benda', colorNoun),
  ('Merah — negasi', colorNegation),
  ('Abu — folder', colorFolder),
  ('Putih', '#FFFFFF'),
];

/// Buka editor sel (tambah baru kalau [cell] null) pada posisi
/// [rowIndex],[colIndex] di papan yang aktif di [EditorState].
Future<void> showCellEditor(
  BuildContext context, {
  required EditorState editor,
  required int rowIndex,
  required int colIndex,
  Cell? cell,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: ChangeNotifierProvider.value(
        value: editor,
        child: _CellEditorSheet(
          rowIndex: rowIndex,
          colIndex: colIndex,
          cell: cell,
        ),
      ),
    ),
  );
}

class _CellEditorSheet extends StatefulWidget {
  const _CellEditorSheet({
    required this.rowIndex,
    required this.colIndex,
    this.cell,
  });

  final int rowIndex;
  final int colIndex;
  final Cell? cell;

  @override
  State<_CellEditorSheet> createState() => _CellEditorSheetState();
}

class _CellEditorSheetState extends State<_CellEditorSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _speakController;
  late String _color;
  late String _actionType;
  String? _targetBoardId;
  Symbol? _symbol;
  bool _labelEmpty = false;
  bool _saving = false;

  bool get _isNew => widget.cell == null;

  @override
  void initState() {
    super.initState();
    final cell = widget.cell;
    _labelController = TextEditingController(text: cell?.label ?? '');
    _speakController = TextEditingController(text: cell?.speakText ?? '');
    _color = cell?.backgroundColor ?? colorNoun;
    _actionType = cell?.actionType ?? 'speak';
    _targetBoardId = cell?.targetBoardId;
    final symbolId = cell?.symbolId;
    if (symbolId != null) {
      _symbol = context.read<EditorState>().current?.symbols[symbolId];
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _speakController.dispose();
    super.dispose();
  }

  Future<void> _pickSymbol() async {
    final picked = await showSymbolPicker(
      context,
      suggestedLabel: _labelController.text,
    );
    if (picked == null) return;
    setState(() {
      _symbol = picked;
      if (_labelController.text.trim().isEmpty) {
        _labelController.text = picked.label;
      }
    });
  }

  Future<void> _createTargetBoard() async {
    final editor = context.read<EditorState>();
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Papan baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama papan',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Buat'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;

    final board = await editor.createBoard(trimmed);
    setState(() => _targetBoardId = board.id);
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      setState(() => _labelEmpty = true);
      return;
    }
    if (_actionType == 'navigate' && _targetBoardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pilih papan tujuan untuk sel folder.')));
      return;
    }
    setState(() => _saving = true);
    final speak = _speakController.text.trim();
    await context.read<EditorState>().saveCell(
          id: widget.cell?.id,
          rowIndex: widget.rowIndex,
          colIndex: widget.colIndex,
          label: label,
          speakText: speak.isEmpty ? null : speak,
          symbolId: _symbol?.id,
          backgroundColor: _color,
          actionType: _actionType,
          targetBoardId: _actionType == 'navigate' ? _targetBoardId : null,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final cell = widget.cell;
    if (cell == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus sel?'),
        content: Text('Sel "${cell.label}" akan dihapus dari papan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<EditorState>().removeCell(cell.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorState>();
    final currentBoardId = editor.current?.board.id;
    final targets =
        editor.boards.where((b) => b.id != currentBoardId).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isNew ? 'Tambah sel' : 'Ubah sel',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (!_isNew)
                IconButton(
                  tooltip: 'Hapus sel',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _delete,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Gambar simbol
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorFromHex(_color),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(6),
                child: _symbol == null
                    ? const Icon(Icons.image_outlined, size: 32)
                    : SymbolImage(symbol: _symbol!),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _pickSymbol,
                      icon: const Icon(Icons.image_search),
                      label: Text(
                          _symbol == null ? 'Pilih gambar' : 'Ganti gambar'),
                    ),
                    if (_symbol != null)
                      TextButton(
                        onPressed: () => setState(() => _symbol = null),
                        child: const Text('Hapus gambar'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _labelController,
            autofocus: _isNew,
            decoration: InputDecoration(
              labelText: 'Label',
              border: const OutlineInputBorder(),
              errorText: _labelEmpty ? 'Label wajib diisi' : null,
            ),
            onChanged: (_) {
              if (_labelEmpty) setState(() => _labelEmpty = false);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _speakController,
            decoration: const InputDecoration(
              labelText: 'Teks yang diucapkan (opsional)',
              helperText: 'Kosongkan untuk mengucapkan label',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          Text('Warna', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (tooltip, hex) in _colorChoices)
                Tooltip(
                  message: tooltip,
                  child: InkWell(
                    onTap: () => setState(() => _color = hex),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorFromHex(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: _color == hex ? 3 : 1,
                          color: _color == hex
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black26,
                        ),
                      ),
                      child: _color == hex
                          ? const Icon(Icons.check, size: 20)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Text('Saat disentuh', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'speak',
                label: Text('Ucapkan'),
                icon: Icon(Icons.record_voice_over_outlined),
              ),
              ButtonSegment(
                value: 'navigate',
                label: Text('Buka papan'),
                icon: Icon(Icons.folder_open),
              ),
            ],
            selected: {_actionType},
            onSelectionChanged: (selection) =>
                setState(() => _actionType = selection.first),
          ),
          if (_actionType == 'navigate') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: targets.any((b) => b.id == _targetBoardId)
                        ? _targetBoardId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Papan tujuan',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final board in targets)
                        DropdownMenuItem(
                          value: board.id,
                          child: Text(board.name),
                        ),
                    ],
                    onChanged: (v) => setState(() => _targetBoardId = v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Buat papan baru',
                  icon: const Icon(Icons.add),
                  onPressed: _createTargetBoard,
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isNew ? 'Tambah' : 'Simpan'),
            ),
          ),
        ],
      ),
    );
  }
}
