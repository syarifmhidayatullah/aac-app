import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/board_repository.dart';
import '../../data/db.dart';
import '../../services/image_store.dart';
import '../widgets/symbol_image.dart';

/// Buka pemilih simbol: cari di pustaka lokal, atau ambil foto dari
/// kamera/galeri (tersimpan sebagai simbol `custom`).
///
/// Mengembalikan [Symbol] terpilih, atau null kalau dibatalkan.
/// [suggestedLabel] dipakai sebagai label awal simbol foto baru.
Future<Symbol?> showSymbolPicker(
  BuildContext context, {
  String suggestedLabel = '',
}) {
  return showModalBottomSheet<Symbol>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _SymbolPickerSheet(suggestedLabel: suggestedLabel),
    ),
  );
}

class _SymbolPickerSheet extends StatefulWidget {
  const _SymbolPickerSheet({required this.suggestedLabel});

  final String suggestedLabel;

  @override
  State<_SymbolPickerSheet> createState() => _SymbolPickerSheetState();
}

class _SymbolPickerSheetState extends State<_SymbolPickerSheet> {
  final _searchController = TextEditingController();
  final _picker = ImagePicker();
  List<Symbol> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final repo = context.read<BoardRepository>();
    final results = await repo.searchSymbols(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final store = context.read<ImageStore>();
    final repo = context.read<BoardRepository>();
    final imageUrl = await store.saveImage(picked);
    final label = widget.suggestedLabel.trim().isEmpty
        ? 'Foto'
        : widget.suggestedLabel.trim();
    final symbol = await repo.createSymbol(label: label, imageUrl: imageUrl);
    if (!mounted) return;
    Navigator.of(context).pop(symbol);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cari simbol…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: _search,
                  ),
                ),
                const SizedBox(width: 8),
                // Kamera tidak tersedia di web/desktop.
                if (!kIsWeb)
                  IconButton.filledTonal(
                    tooltip: 'Ambil foto',
                    icon: const Icon(Icons.photo_camera_outlined),
                    onPressed: () => _pickPhoto(ImageSource.camera),
                  ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  tooltip: 'Pilih dari galeri',
                  icon: const Icon(Icons.photo_library_outlined),
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada simbol.\nAmbil foto atau pilih dari galeri.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 110,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final symbol = _results[index];
                          return InkWell(
                            onTap: () => Navigator.of(context).pop(symbol),
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              children: [
                                Expanded(
                                    child: SymbolImage(symbol: symbol)),
                                const SizedBox(height: 4),
                                Text(
                                  symbol.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
