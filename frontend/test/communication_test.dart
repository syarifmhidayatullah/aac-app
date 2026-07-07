import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aac_app/data/board_repository.dart';
import 'package:aac_app/data/db.dart';
import 'package:aac_app/data/seed.dart';
import 'package:aac_app/services/speech_service.dart';
import 'package:aac_app/state/communication_state.dart';

class FakeSpeech implements SpeechService {
  final List<String> spoken = [];

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

void main() {
  late AppDatabase db;
  late FakeSpeech speech;
  late CommunicationState state;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    final profileId = await seedIfEmpty(db);
    speech = FakeSpeech();
    state = CommunicationState(
      repository: BoardRepository(db),
      speech: speech,
      profileId: profileId,
    );
    await state.loadRoot();
  });

  tearDown(() async {
    await db.close();
  });

  test('seed membuat papan utama dengan kosakata inti', () {
    final board = state.current!;
    expect(board.board.name, 'Papan Utama');
    expect(board.board.isRoot, isTrue);
    expect(board.board.gridRows, 5);
    expect(board.board.gridCols, 6);
    // 24 sel bicara + 2 sel navigasi (Makanan, Minuman).
    expect(board.cells.length, 26);
  });

  test('seed hanya berjalan sekali', () async {
    final again = await seedIfEmpty(db);
    final profiles = await db.select(db.profiles).get();
    expect(profiles.length, 1);
    expect(again, profiles.single.id);
  });

  test('tap sel bicara: mengucapkan kata dan menambah kalimat', () async {
    final mau =
        state.current!.cells.firstWhere((c) => c.label == 'Mau');
    final makan =
        state.current!.cells.firstWhere((c) => c.label == 'Makan');

    await state.tapCell(mau);
    await state.tapCell(makan);

    expect(speech.spoken, ['Mau', 'Makan']);
    expect(state.sentence.map((c) => c.label), ['Mau', 'Makan']);
  });

  test('play sentence mengucapkan seluruh kalimat', () async {
    final aku = state.current!.cells.firstWhere((c) => c.label == 'Aku');
    final mau = state.current!.cells.firstWhere((c) => c.label == 'Mau');
    await state.tapCell(aku);
    await state.tapCell(mau);
    speech.spoken.clear();

    await state.playSentence();
    expect(speech.spoken, ['Aku Mau']);
  });

  test('backspace dan clear mengubah kalimat', () async {
    final aku = state.current!.cells.firstWhere((c) => c.label == 'Aku');
    await state.tapCell(aku);
    await state.tapCell(aku);

    state.backspace();
    expect(state.sentence.length, 1);
    state.clearSentence();
    expect(state.sentence, isEmpty);
  });

  test('tap sel navigasi membuka papan tujuan, back kembali', () async {
    final makanan =
        state.current!.cells.firstWhere((c) => c.label == 'Makanan');
    expect(makanan.actionType, 'navigate');

    await state.tapCell(makanan);
    expect(state.current!.board.name, 'Makanan');
    expect(state.canGoBack, isTrue);
    // Navigasi tidak menambah kalimat dan tidak bersuara.
    expect(state.sentence, isEmpty);
    expect(speech.spoken, isEmpty);
    // Isi papan makanan bisa diucapkan.
    final nasi =
        state.current!.cells.firstWhere((c) => c.label == 'Nasi');
    await state.tapCell(nasi);
    expect(speech.spoken, ['Nasi']);

    state.goBack();
    expect(state.current!.board.name, 'Papan Utama');
    expect(state.canGoBack, isFalse);
  });
}
