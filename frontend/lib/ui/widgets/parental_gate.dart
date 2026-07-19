import 'dart:math';

import 'package:flutter/material.dart';

/// Gerbang orang tua: soal perkalian sederhana yang mudah bagi orang
/// dewasa tapi menyulitkan anak — pola umum di app AAC (mis.
/// Proloquo2Go) sebelum masuk mode edit.
///
/// Jawaban diketik lewat keypad angka custom (bukan keyboard sistem),
/// jadi tidak bergantung pada perilaku on-screen keyboard iOS yang bisa
/// gagal muncul lagi setelah ditutup manual di iPad.
///
/// Mengembalikan `true` kalau jawaban benar.
Future<bool> showParentalGate(BuildContext context) async {
  final rng = Random();
  final a = 11 + rng.nextInt(9); // 11..19
  final b = 3 + rng.nextInt(7); // 3..9
  final answer = a * b;

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => _ParentalGateDialog(a: a, b: b, answer: answer),
  );
  return ok ?? false;
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog({
    required this.a,
    required this.b,
    required this.answer,
  });

  final int a;
  final int b;
  final int answer;

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  String _input = '';
  bool _wrong = false;

  void _submit() {
    final value = int.tryParse(_input);
    if (value == widget.answer) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _wrong = true;
        _input = '';
      });
    }
  }

  void _tapDigit(String d) {
    if (_input.length >= 3) return; // jawaban maks 3 digit (19*9=171)
    setState(() {
      _input += d;
      _wrong = false;
    });
  }

  void _backspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Khusus orang tua'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Untuk masuk mode edit, jawab dulu:\n'
            '${widget.a} × ${widget.b} = ?',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: _wrong
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).dividerColor,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _input.isEmpty ? ' ' : _input,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (_wrong)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Jawaban salah, coba lagi',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 16),
          _NumberPad(onDigit: _tapDigit, onBackspace: _backspace),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _input.isEmpty ? null : _submit,
          child: const Text('Masuk'),
        ),
      ],
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final d in row) _digitButton(context, d),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 56, height: 56),
            _digitButton(context, '0'),
            SizedBox(
              width: 56,
              height: 56,
              child: IconButton(
                onPressed: onBackspace,
                tooltip: 'Hapus',
                icon: const Icon(Icons.backspace_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _digitButton(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 56,
        height: 56,
        child: OutlinedButton(
          onPressed: () => onDigit(label),
          style: OutlinedButton.styleFrom(shape: const CircleBorder()),
          child: Text(label, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}
