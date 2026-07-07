import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'db.dart';

/// Warna latar sel mengikuti konvensi Fitzgerald key (sinkron dengan
/// seed backend: internal/service/seed.go).
const colorPronoun = '#FFE082'; // kuning: kata ganti orang
const colorVerb = '#A5D6A7'; // hijau: kata kerja
const colorDescriptor = '#90CAF9'; // biru: kata sifat/keterangan
const colorSocial = '#F8BBD0'; // pink: kata sosial
const colorNoun = '#FFCC80'; // oranye: kata benda
const colorNegation = '#EF9A9A'; // merah: negasi/penolakan
const colorFolder = '#B0BEC5'; // abu: navigasi ke papan lain

const _uuid = Uuid();

class _CellSpec {
  const _CellSpec(this.label, this.color, {this.navigateTo});
  final String label;
  final String color;
  final String? navigateTo; // nama papan tujuan (di-resolve saat seeding)
}

/// Mengisi database dengan profile default + papan kosakata inti
/// Bahasa Indonesia kalau masih kosong. Mengembalikan id profile aktif.
Future<String> seedIfEmpty(AppDatabase db) async {
  final existing = await db.select(db.profiles).getSingleOrNull();
  if (existing != null) return existing.id;

  final profileId = _uuid.v4();

  final makananId = _uuid.v4();
  final minumanId = _uuid.v4();
  final rootId = _uuid.v4();

  final boards = <String, ({String id, int rows, int cols, bool isRoot, List<List<_CellSpec>> grid})>{
    'Papan Utama': (
      id: rootId,
      rows: 5,
      cols: 6,
      isRoot: true,
      grid: [
        [
          const _CellSpec('Aku', colorPronoun),
          const _CellSpec('Kamu', colorPronoun),
          const _CellSpec('Mau', colorVerb),
          const _CellSpec('Tidak mau', colorNegation),
          const _CellSpec('Suka', colorVerb),
          const _CellSpec('Tidak suka', colorNegation),
        ],
        [
          const _CellSpec('Makan', colorVerb),
          const _CellSpec('Minum', colorVerb),
          const _CellSpec('Main', colorVerb),
          const _CellSpec('Tidur', colorVerb),
          const _CellSpec('Toilet', colorNoun),
          const _CellSpec('Tolong', colorSocial),
        ],
        [
          const _CellSpec('Lagi', colorDescriptor),
          const _CellSpec('Sudah', colorDescriptor),
          const _CellSpec('Ya', colorSocial),
          const _CellSpec('Tidak', colorNegation),
          const _CellSpec('Sakit', colorDescriptor),
          const _CellSpec('Capek', colorDescriptor),
        ],
        [
          const _CellSpec('Senang', colorDescriptor),
          const _CellSpec('Sedih', colorDescriptor),
          const _CellSpec('Marah', colorDescriptor),
          const _CellSpec('Takut', colorDescriptor),
          const _CellSpec('Halo', colorSocial),
          const _CellSpec('Terima kasih', colorSocial),
        ],
        [
          const _CellSpec('Makanan', colorFolder, navigateTo: 'Makanan'),
          const _CellSpec('Minuman', colorFolder, navigateTo: 'Minuman'),
        ],
      ],
    ),
    'Makanan': (
      id: makananId,
      rows: 3,
      cols: 4,
      isRoot: false,
      grid: [
        [
          const _CellSpec('Nasi', colorNoun),
          const _CellSpec('Roti', colorNoun),
          const _CellSpec('Bubur', colorNoun),
          const _CellSpec('Telur', colorNoun),
        ],
        [
          const _CellSpec('Ayam', colorNoun),
          const _CellSpec('Ikan', colorNoun),
          const _CellSpec('Sayur', colorNoun),
          const _CellSpec('Buah', colorNoun),
        ],
        [
          const _CellSpec('Pisang', colorNoun),
          const _CellSpec('Apel', colorNoun),
          const _CellSpec('Kue', colorNoun),
          const _CellSpec('Es krim', colorNoun),
        ],
      ],
    ),
    'Minuman': (
      id: minumanId,
      rows: 2,
      cols: 4,
      isRoot: false,
      grid: [
        [
          const _CellSpec('Air putih', colorNoun),
          const _CellSpec('Susu', colorNoun),
          const _CellSpec('Teh', colorNoun),
          const _CellSpec('Jus', colorNoun),
        ],
        [
          const _CellSpec('Es teh', colorNoun),
          const _CellSpec('Cokelat', colorNoun),
        ],
      ],
    ),
  };

  final boardIdByName = {
    for (final entry in boards.entries) entry.key: entry.value.id,
  };

  await db.transaction(() async {
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(id: profileId, name: 'Profil Utama'),
        );

    for (final entry in boards.entries) {
      final b = entry.value;
      await db.into(db.boards).insert(BoardsCompanion.insert(
            id: b.id,
            profileId: profileId,
            name: entry.key,
            gridRows: Value(b.rows),
            gridCols: Value(b.cols),
            isRoot: Value(b.isRoot),
          ));

      for (var r = 0; r < b.grid.length; r++) {
        for (var c = 0; c < b.grid[r].length; c++) {
          final spec = b.grid[r][c];
          final isNavigate = spec.navigateTo != null;
          await db.into(db.cells).insert(CellsCompanion.insert(
                id: _uuid.v4(),
                boardId: b.id,
                rowIndex: r,
                colIndex: c,
                label: spec.label,
                backgroundColor: Value(spec.color),
                actionType: Value(isNavigate ? 'navigate' : 'speak'),
                targetBoardId: Value(
                  isNavigate ? boardIdByName[spec.navigateTo] : null,
                ),
              ));
        }
      }
    }
  });

  return profileId;
}
