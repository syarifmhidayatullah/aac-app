import 'package:flutter/material.dart';

import '../../data/db.dart';
import 'symbol_image.dart';

Color colorFromHex(String? hex, {Color fallback = Colors.white}) {
  if (hex == null || hex.isEmpty) return fallback;
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

/// Satu sel papan: target tap besar, gambar simbol (kalau ada), label
/// jelas, ikon folder untuk sel navigasi.
class CellTile extends StatelessWidget {
  const CellTile({
    super.key,
    required this.cell,
    required this.onTap,
    this.symbol,
    this.onLongPress,
  });

  final Cell cell;
  final Symbol? symbol;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final background = colorFromHex(cell.backgroundColor);
    final isNavigate = cell.actionType == 'navigate';
    final hasImage = symbol?.imageUrl?.isNotEmpty ?? false;

    return MergeSemantics(
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasImage)
                  Expanded(child: SymbolImage(symbol: symbol!))
                else if (isNavigate) ...[
                  const Icon(Icons.folder_open,
                      size: 28, semanticLabel: 'Folder'),
                  const SizedBox(height: 4),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      cell.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
