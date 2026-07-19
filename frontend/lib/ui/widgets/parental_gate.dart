import 'dart:math';

import 'package:flutter/material.dart';

/// Gerbang orang tua: soal perkalian sederhana yang mudah bagi orang
/// dewasa tapi menyulitkan anak — pola umum di app AAC (mis.
/// Proloquo2Go) sebelum masuk mode edit.
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
  final _controller = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == widget.answer) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _wrong = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Khusus orang tua'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Untuk masuk mode edit, jawab dulu:\n'
            '${widget.a} × ${widget.b} = ?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: _wrong ? 'Jawaban salah, coba lagi' : null,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Masuk'),
        ),
      ],
    );
  }
}
