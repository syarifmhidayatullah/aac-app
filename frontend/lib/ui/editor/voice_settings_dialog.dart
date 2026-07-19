import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/board_repository.dart';
import '../../services/speech_service.dart';

/// Dialog pengaturan suara TTS per profile: kecepatan & pitch,
/// dengan tombol coba. Tersimpan di profiles.settings (ikut sync).
Future<void> showVoiceSettings(BuildContext context, String profileId) async {
  final repository = context.read<BoardRepository>();
  final speech = context.read<SpeechService>();

  final profile = await repository.getProfile(profileId);
  final settings =
      (jsonDecode(profile.settings) as Map<String, dynamic>?) ?? {};
  var rate = (settings['tts_rate'] as num?)?.toDouble() ?? 0.5;
  var pitch = (settings['tts_pitch'] as num?)?.toDouble() ?? 1.0;

  if (!context.mounted) return;
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Pengaturan suara'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kecepatan', style: Theme.of(context).textTheme.labelLarge),
            Slider(
              value: rate,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: rate.toStringAsFixed(1),
              onChanged: (v) => setState(() => rate = v),
            ),
            Text('Tinggi nada', style: Theme.of(context).textTheme.labelLarge),
            Slider(
              value: pitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: pitch.toStringAsFixed(1),
              onChanged: (v) => setState(() => pitch = v),
            ),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.volume_up),
                label: const Text('Coba suara'),
                onPressed: () async {
                  await speech.configure(rate: rate, pitch: pitch);
                  await speech.speak('Halo, aku mau makan.');
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );

  if (saved == true) {
    await repository.updateProfileSettings(profileId, {
      'tts_rate': rate,
      'tts_pitch': pitch,
    });
  }
  // Kembalikan engine ke pengaturan tersimpan (batal = setelan lama).
  final fresh = await repository.getProfile(profileId);
  final s = (jsonDecode(fresh.settings) as Map<String, dynamic>?) ?? {};
  await speech.configure(
    rate: (s['tts_rate'] as num?)?.toDouble() ?? 0.5,
    pitch: (s['tts_pitch'] as num?)?.toDouble() ?? 1.0,
  );
}
