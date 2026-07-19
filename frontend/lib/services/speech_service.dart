import 'package:flutter_tts/flutter_tts.dart';

/// Abstraksi TTS supaya bisa diganti fake di test (flutter_tts memakai
/// platform channel yang tidak tersedia di widget/unit test).
abstract class SpeechService {
  Future<void> speak(String text);
  Future<void> stop();

  /// Atur kecepatan (0.1–1.0, default 0.5) dan pitch (0.5–2.0,
  /// default 1.0). Dipanggil saat profile dimuat & saat pengaturan
  /// suara diubah.
  Future<void> configure({double? rate, double? pitch});
}

class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService({this.language = 'id-ID'});

  final String language;
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  double _rate = 0.5;
  double _pitch = 1.0;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);
    _initialized = true;
  }

  @override
  Future<void> configure({double? rate, double? pitch}) async {
    if (rate != null) _rate = rate.clamp(0.1, 1.0);
    if (pitch != null) _pitch = pitch.clamp(0.5, 2.0);
    if (!_initialized) return; // dipakai saat init pertama
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);
  }

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureInitialized();
    // Hentikan ucapan sebelumnya supaya tap beruntun terasa responsif.
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
