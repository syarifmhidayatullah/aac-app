import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aac_app/data/board_repository.dart';
import 'package:aac_app/data/db.dart';
import 'package:aac_app/data/seed.dart';
import 'package:aac_app/main.dart';
import 'package:aac_app/services/image_store.dart';
import 'package:aac_app/state/account_state.dart';

import 'communication_test.dart' show FakeSpeech;

void main() {
  late AppDatabase db;
  late FakeSpeech speech;

  Future<AacApp> buildApp() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    final profileId = await seedIfEmpty(db);
    speech = FakeSpeech();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return AacApp(
      database: db,
      repository: BoardRepository(db),
      profileId: profileId,
      speech: speech,
      imageStore: ImageStore.forTesting(Directory.systemTemp),
      account: AccountState(db: db, prefs: prefs)..init(),
    );
  }

  tearDown(() async {
    await db.close();
  });

  testWidgets('papan utama tampil dan tap sel menyusun kalimat',
      (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Papan Utama'), findsOneWidget);
    expect(find.text('Ketuk simbol untuk menyusun kalimat…'), findsOneWidget);

    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();

    // Muncul di grid + sentence strip.
    expect(find.text('Makan'), findsNWidgets(2));
    expect(speech.spoken, ['Makan']);
  });

  testWidgets('sel folder membuka papan tujuan dan bisa kembali',
      (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Minuman'));
    await tester.pumpAndSettle();

    expect(find.text('Susu'), findsOneWidget);
    expect(speech.spoken, isEmpty, reason: 'navigasi tidak bersuara');

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Papan Utama'), findsOneWidget);
  });

  testWidgets('mode edit dijaga parental gate', (tester) async {
    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mode edit (orang tua)'));
    await tester.pumpAndSettle();

    expect(find.text('Khusus orang tua'), findsOneWidget);

    // Jawaban salah tidak membuka editor.
    await tester.tap(find.widgetWithText(OutlinedButton, '1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Jawaban salah, coba lagi'), findsOneWidget);
    expect(find.text('Mode edit'), findsNothing);
  });
}
