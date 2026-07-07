import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/communication_state.dart';
import 'cell_tile.dart';

/// Baris penyusun kalimat di atas papan: kata-kata yang sudah dipilih,
/// tombol ucapkan, hapus satu, dan bersihkan.
class SentenceStrip extends StatelessWidget {
  const SentenceStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CommunicationState>();
    final theme = Theme.of(context);

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: state.sentence.isEmpty
                ? Text(
                    'Ketuk simbol untuk menyusun kalimat…',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.hintColor,
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.sentence.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final cell = state.sentence[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorFromHex(cell.backgroundColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cell.label,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Ucapkan kalimat',
            iconSize: 32,
            onPressed:
                state.sentence.isEmpty ? null : () => state.playSentence(),
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            tooltip: 'Hapus kata terakhir',
            iconSize: 28,
            onPressed: state.sentence.isEmpty ? null : state.backspace,
            icon: const Icon(Icons.backspace_outlined),
          ),
          IconButton(
            tooltip: 'Bersihkan kalimat',
            iconSize: 28,
            onPressed: state.sentence.isEmpty ? null : state.clearSentence,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
