import 'package:flutter/foundation.dart';

import '../data/board_repository.dart';
import '../data/db.dart';
import '../services/speech_service.dart';

/// State layar komunikasi: papan yang sedang tampil (dengan riwayat
/// navigasi) dan kalimat yang sedang disusun di sentence strip.
class CommunicationState extends ChangeNotifier {
  CommunicationState({
    required BoardRepository repository,
    required SpeechService speech,
    required String profileId,
  })  : _repository = repository,
        _speech = speech,
        _profileId = profileId;

  final BoardRepository _repository;
  final SpeechService _speech;
  final String _profileId;

  final List<BoardWithCells> _stack = [];
  final List<Cell> _sentence = [];
  bool _loading = true;

  bool get loading => _loading;
  BoardWithCells? get current => _stack.isEmpty ? null : _stack.last;
  bool get canGoBack => _stack.length > 1;
  List<Cell> get sentence => List.unmodifiable(_sentence);

  Future<void> loadRoot() async {
    _loading = true;
    notifyListeners();
    final root = await _repository.getRootBoard(_profileId);
    _stack
      ..clear()
      ..add(root);
    _loading = false;
    notifyListeners();
  }

  /// Tap sel: 'navigate' membuka papan tujuan; 'speak' mengucapkan
  /// kata sekaligus menambahkannya ke kalimat.
  Future<void> tapCell(Cell cell) async {
    if (cell.actionType == 'navigate') {
      final targetId = cell.targetBoardId;
      if (targetId == null) return;
      final target = await _repository.getBoard(targetId);
      if (target == null) return;
      _stack.add(target);
      notifyListeners();
      return;
    }

    _sentence.add(cell);
    notifyListeners();
    await _speech.speak(cell.speakText ?? cell.label);
  }

  void goBack() {
    if (!canGoBack) return;
    _stack.removeLast();
    notifyListeners();
  }

  void goHome() {
    if (_stack.length <= 1) return;
    _stack.removeRange(1, _stack.length);
    notifyListeners();
  }

  Future<void> playSentence() async {
    if (_sentence.isEmpty) return;
    final text =
        _sentence.map((c) => c.speakText ?? c.label).join(' ');
    await _speech.speak(text);
  }

  void backspace() {
    if (_sentence.isEmpty) return;
    _sentence.removeLast();
    notifyListeners();
  }

  void clearSentence() {
    if (_sentence.isEmpty) return;
    _sentence.clear();
    notifyListeners();
  }
}
