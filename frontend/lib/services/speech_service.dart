import 'package:flutter_tts/flutter_tts.dart';

/// Abstraksi TTS supaya bisa diganti fake di test (flutter_tts memakai
/// platform channel yang tidak tersedia di widget/unit test).
abstract class SpeechService {
  Future<void> speak(String text);
  Future<void> stop();
}

class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService({this.language = 'id-ID', this.rate = 0.5});

  final String language;
  final double rate;
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(rate);
    _initialized = true;
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
