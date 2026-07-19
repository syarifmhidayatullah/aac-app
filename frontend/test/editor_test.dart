import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aac_app/data/board_repository.dart';
import 'package:aac_app/data/db.dart';
import 'package:aac_app/data/seed.dart';
import 'package:aac_app/state/editor_state.dart';

void main() {
  late AppDatabase db;
  late BoardRepository repository;
  late EditorState editor;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    final profileId = await seedIfEmpty(db);
    repository = BoardRepository(db);
    editor = EditorState(repository: repository, profileId: profileId);
    await editor.load();
  });

  tearDown(() async {
    await db.close();
  });

  test('load membuka papan utama dan daftar papan', () {
    expect(editor.current!.board.isRoot, isTrue);
    // Papan utama diurutkan duluan.
    expect(editor.boards.first.isRoot, isTrue);
    expect(editor.boards.map((b) => b.name),
        containsAll(['Papan Utama', 'Makanan', 'Minuman']));
  });

  test('saveCell menambah sel baru di slot kosong', () async {
    // Baris terakhir papan utama hanya terisi kolom 0-1.
    expect(editor.cellAt(4, 2), isNull);

    await editor.saveCell(
      rowIndex: 4,
      colIndex: 2,
      label: 'Sekolah',
      backgroundColor: colorNoun,
    );

    final added = editor.cellAt(4, 2)!;
    expect(added.label, 'Sekolah');
    expect(added.actionType, 'speak');
    expect(added.dirty, isTrue);
  });

  test('saveCell dengan id mengubah sel yang ada', () async {
    final aku = editor.cellAt(0, 0)!;
    expect(aku.label, 'Aku');

    await editor.saveCell(
      id: aku.id,
      rowIndex: aku.rowIndex,
      colIndex: aku.colIndex,
      label: 'Saya',
      speakText: 'Saya',
      backgroundColor: aku.backgroundColor,
    );

    final updated = editor.cellAt(0, 0)!;
    expect(updated.id, aku.id);
    expect(updated.label, 'Saya');
    expect(updated.speakText, 'Saya');
  });

  test('removeCell = soft delete (tombstone tetap ada untuk sync)',
      () async {
    final cell = editor.cellAt(0, 0)!;
    await editor.removeCell(cell.id);

    expect(editor.cellAt(0, 0), isNull);

    final row = await (db.select(db.cells)
          ..where((c) => c.id.equals(cell.id)))
        .getSingle();
    expect(row.deletedAt, isNotNull);
    expect(row.dirty, isTrue);
  });

  test('updateBoardSettings mengubah nama & ukuran grid tanpa '
      'menghapus sel di luar grid', () async {
    await editor.updateBoardSettings(name: 'Papan Inti', rows: 3, cols: 6);

    final board = editor.current!.board;
    expect(board.name, 'Papan Inti');
    expect(board.gridRows, 3);

    // Sel baris 3-4 tidak dihapus dari DB — muncul lagi saat diperbesar.
    await editor.updateBoardSettings(rows: 5);
    expect(editor.cellAt(4, 0)!.label, 'Makanan');
  });

  test('createBoard menambah papan dan bisa jadi target navigasi',
      () async {
    final board = await editor.createBoard('Sekolah');
    expect(editor.boards.map((b) => b.name), contains('Sekolah'));

    await editor.saveCell(
      rowIndex: 4,
      colIndex: 2,
      label: 'Sekolah',
      backgroundColor: colorFolder,
      actionType: 'navigate',
      targetBoardId: board.id,
    );

    final cell = editor.cellAt(4, 2)!;
    expect(cell.actionType, 'navigate');
    expect(cell.targetBoardId, board.id);

    await editor.switchBoard(board.id);
    expect(editor.current!.board.name, 'Sekolah');
    expect(editor.current!.cells, isEmpty);
  });

  test('seed mengisi pustaka Mulberry dan menautkannya ke sel', () async {
    final symbols = await repository.searchSymbols('');
    expect(symbols.length, 98);
    expect(symbols.every((s) => s.pack == 'mulberry'), isTrue);
    expect(
        symbols.every(
            (s) => s.imageUrl!.startsWith('assets/symbols/mulberry/')),
        isTrue);

    // Sel "Makan" tertaut ke simbol eat.svg, dan ikut termuat di
    // BoardWithCells.symbols.
    final makan = editor.current!.cells.firstWhere((c) => c.label == 'Makan');
    expect(makan.symbolId, isNotNull);
    final symbol = editor.current!.symbols[makan.symbolId];
    expect(symbol!.imageUrl, 'assets/symbols/mulberry/eat.svg');
  });

  test('searchSymbols mencari lewat label dan keyword', () async {
    final byLabel = await repository.searchSymbols('nasi');
    expect(byLabel.map((s) => s.label), contains('Nasi'));

    // 'bantu' hanya ada di keywords simbol Tolong.
    final byKeyword = await repository.searchSymbols('bantu');
    expect(byKeyword.map((s) => s.label), contains('Tolong'));

    final none = await repository.searchSymbols('zzz-tidak-ada');
    expect(none, isEmpty);
  });

  test('searchSymbols dengan limit+offset paging tanpa duplikat/kelewat',
      () async {
    const pageSize = 60;
    final page1 = await repository.searchSymbols('', limit: pageSize);
    expect(page1.length, pageSize);

    final page2 = await repository.searchSymbols('',
        limit: pageSize, offset: pageSize);
    expect(page2.length, 98 - pageSize);

    final page1Ids = page1.map((s) => s.id).toSet();
    final page2Ids = page2.map((s) => s.id).toSet();
    expect(page1Ids.intersection(page2Ids), isEmpty);
    expect(page1Ids.length + page2Ids.length, 98);

    // Gabungan dua halaman = hasil tanpa paging sama sekali.
    final all = await repository.searchSymbols('');
    expect({...page1Ids, ...page2Ids}, all.map((s) => s.id).toSet());
  });

  test('symbolCategoriesInUse mengembalikan kategori sesuai urutan',
      () async {
    final categories = await repository.symbolCategoriesInUse();
    expect(categories, isNotEmpty);
    expect(categories, containsAll(['Dasar', 'Warna', 'Hewan']));
    // Urutannya harus mengikuti symbolCategories, bukan alfabetis.
    final expectedOrder =
        symbolCategories.where(categories.contains).toList();
    expect(categories, expectedOrder);
  });

  test('createSymbol mendaftarkan simbol custom yang bisa dicari',
      () async {
    final symbol = await repository.createSymbol(
      label: 'Boneka',
      imageUrl: 'images/boneka.jpg',
      keywords: ['boneka', 'mainan'],
    );
    expect(symbol.pack, 'custom');

    final found = await repository.searchSymbols('mainan');
    expect(found.map((s) => s.id), contains(symbol.id));
  });
}
