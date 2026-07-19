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
  const _CellSpec(this.label, this.color, {this.navigateTo, this.symbol});
  final String label;
  final String color;
  final String? navigateTo; // nama papan tujuan (di-resolve saat seeding)
  final String? symbol; // nama file (tanpa .svg) di pustaka Mulberry
}

class _SymbolSpec {
  const _SymbolSpec(this.label, this.keywords, this.packRef);
  final String label;
  final List<String> keywords;
  final String packRef; // nama file asli di repo mulberry-symbols/EN
}

const _mulberryLicense = 'CC BY-SA 2.0 UK';

/// Pustaka simbol bawaan: subset Mulberry Symbols dengan label &
/// keyword Bahasa Indonesia (file: assets/symbols/mulberry/<key>.svg).
const _mulberrySymbols = <String, _SymbolSpec>{
  'i': _SymbolSpec('Aku', ['aku', 'saya'], 'I.svg'),
  'want': _SymbolSpec('Mau', ['mau', 'ingin'], 'want_,_to.svg'),
  'good': _SymbolSpec('Suka', ['suka', 'bagus', 'baik'], 'good.svg'),
  'bad': _SymbolSpec('Tidak suka', ['tidak suka', 'jelek'], 'bad.svg'),
  'eat': _SymbolSpec('Makan', ['makan'], 'eat_,_to.svg'),
  'drink': _SymbolSpec('Minum', ['minum'], 'drink_,_to.svg'),
  'play': _SymbolSpec('Main', ['main', 'bermain'], 'play_,_to.svg'),
  'sleep': _SymbolSpec('Tidur', ['tidur'], 'sleep_male_,_to.svg'),
  'toilet': _SymbolSpec('Toilet', ['toilet', 'wc', 'kamar mandi'], 'toilet.svg'),
  'help': _SymbolSpec('Tolong', ['tolong', 'bantu'], 'help_,_to.svg'),
  'more': _SymbolSpec('Lagi', ['lagi', 'tambah'], 'more.svg'),
  'finish': _SymbolSpec('Sudah', ['sudah', 'selesai'], 'finish.svg'),
  'yes': _SymbolSpec('Ya', ['ya', 'iya', 'setuju'], 'nod_,_to.svg'),
  'no': _SymbolSpec('Tidak', ['tidak', 'bukan'], 'cross.svg'),
  'sick': _SymbolSpec('Sakit', ['sakit', 'pusing'], 'headache.svg'),
  'happy': _SymbolSpec('Senang', ['senang', 'bahagia', 'gembira'], 'happy_man.svg'),
  'sad': _SymbolSpec('Sedih', ['sedih'], 'sad_man.svg'),
  'angry': _SymbolSpec('Marah', ['marah'], 'angry_man.svg'),
  'afraid': _SymbolSpec('Takut', ['takut'], 'afraid_man.svg'),
  'hello': _SymbolSpec('Halo', ['halo', 'hai'], 'hello.svg'),
  'rice': _SymbolSpec('Nasi', ['nasi'], 'rice.svg'),
  'bread': _SymbolSpec('Roti', ['roti'], 'bread.svg'),
  'porridge': _SymbolSpec('Bubur', ['bubur'], 'porridge.svg'),
  'egg': _SymbolSpec('Telur', ['telur'], 'egg.svg'),
  'chicken': _SymbolSpec('Ayam', ['ayam'], 'chicken.svg'),
  'fish': _SymbolSpec('Ikan', ['ikan'], 'fish.svg'),
  'vegetables': _SymbolSpec('Sayur', ['sayur', 'sayuran'], 'vegetables.svg'),
  'fruit': _SymbolSpec('Buah', ['buah'], 'fruit.svg'),
  'banana': _SymbolSpec('Pisang', ['pisang'], 'banana.svg'),
  'apple': _SymbolSpec('Apel', ['apel'], 'apple.svg'),
  'cake': _SymbolSpec('Kue', ['kue'], 'cake.svg'),
  'ice_cream': _SymbolSpec('Es krim', ['es krim'], 'ice_cream.svg'),
  'water': _SymbolSpec('Air putih', ['air', 'air putih'], 'water.svg'),
  'milk': _SymbolSpec('Susu', ['susu'], 'milk.svg'),
  'tea': _SymbolSpec('Teh', ['teh'], 'tea.svg'),
  'orange_juice': _SymbolSpec('Jus', ['jus', 'jus jeruk'], 'orange_juice.svg'),
  'drink_cold': _SymbolSpec('Es teh', ['es teh', 'minuman dingin'], 'drink_cold.svg'),
  'hot_chocolate': _SymbolSpec('Cokelat', ['cokelat', 'cokelat panas'], 'hot_chocolate.svg'),

  // Tambahan (belum dipasang ke papan manapun, tersedia lewat pencarian
  // simbol di editor papan) — keluarga.
  'mum': _SymbolSpec('Mama', ['mama', 'ibu', 'bunda'], 'mum_parent.svg'),
  'dad': _SymbolSpec('Papa', ['papa', 'ayah', 'bapak'], 'dad_parent.svg'),
  'baby': _SymbolSpec('Bayi', ['bayi', 'adik bayi'], 'baby.svg'),
  'brother': _SymbolSpec('Saudara laki-laki', ['kakak laki-laki', 'adik laki-laki', 'saudara laki-laki'], 'brother.svg'),
  'sister': _SymbolSpec('Saudara perempuan', ['kakak perempuan', 'adik perempuan', 'saudara perempuan'], 'sister.svg'),

  // Kata kerja.
  'go': _SymbolSpec('Pergi', ['pergi'], 'go_,_to.svg'),
  'come': _SymbolSpec('Datang', ['datang', 'kesini'], 'come_,_to.svg'),
  'close': _SymbolSpec('Tutup', ['tutup'], 'close_,_to.svg'),
  'open': _SymbolSpec('Buka', ['buka'], 'open.svg'),
  'look': _SymbolSpec('Lihat', ['lihat', 'liat'], 'look_,_to.svg'),
  'hear': _SymbolSpec('Dengar', ['dengar', 'denger'], 'hear_,_to.svg'),
  'give': _SymbolSpec('Kasih', ['kasih', 'berikan', 'kasih ke aku'], 'give_,_to.svg'),
  'take': _SymbolSpec('Ambil', ['ambil'], 'take_,_to.svg'),
  'put': _SymbolSpec('Taruh', ['taruh', 'taro'], 'put_,_to.svg'),
  'sit': _SymbolSpec('Duduk', ['duduk'], 'sit_,_to.svg'),
  'stand': _SymbolSpec('Berdiri', ['berdiri'], 'stand_,_to.svg'),
  'walk': _SymbolSpec('Jalan', ['jalan', 'berjalan'], 'walk_,_to.svg'),
  'run': _SymbolSpec('Lari', ['lari', 'berlari'], 'run_,_to.svg'),
  'jump': _SymbolSpec('Lompat', ['lompat'], 'jump_,_to.svg'),
  'wash_hands': _SymbolSpec('Cuci tangan', ['cuci tangan'], 'wash_hands_,_to.svg'),
  'wait': _SymbolSpec('Tunggu', ['tunggu'], 'wait_,_to.svg'),

  // Warna.
  'red': _SymbolSpec('Merah', ['merah'], 'red.svg'),
  'blue': _SymbolSpec('Biru', ['biru'], 'blue.svg'),
  'green': _SymbolSpec('Hijau', ['hijau'], 'green.svg'),
  'yellow': _SymbolSpec('Kuning', ['kuning'], 'yellow.svg'),
  'black': _SymbolSpec('Hitam', ['hitam'], 'black.svg'),
  'white': _SymbolSpec('Putih', ['putih'], 'white.svg'),

  // Konsep / lawan kata.
  'hot': _SymbolSpec('Panas', ['panas'], 'hot.svg'),
  'up': _SymbolSpec('Atas', ['atas', 'naik'], 'up.svg'),
  'down': _SymbolSpec('Bawah', ['bawah', 'turun'], 'down.svg'),
  'in': _SymbolSpec('Dalam', ['dalam', 'masuk'], 'in.svg'),
  'out': _SymbolSpec('Luar', ['luar', 'keluar'], 'out.svg'),
  'on': _SymbolSpec('Nyala', ['nyala', 'hidupkan'], 'on.svg'),
  'off': _SymbolSpec('Mati', ['mati', 'matikan'], 'off.svg'),
  'same': _SymbolSpec('Sama', ['sama'], 'same.svg'),

  // Kata tanya.
  'where': _SymbolSpec('Dimana', ['dimana', 'di mana'], 'where.svg'),
  'what': _SymbolSpec('Apa', ['apa'], 'what.svg'),
  'who': _SymbolSpec('Siapa', ['siapa'], 'who.svg'),
  'why': _SymbolSpec('Kenapa', ['kenapa', 'mengapa'], 'why.svg'),
  'when': _SymbolSpec('Kapan', ['kapan'], 'when.svg'),
  'how': _SymbolSpec('Bagaimana', ['bagaimana', 'gimana'], 'how.svg'),

  // Waktu.
  'now': _SymbolSpec('Sekarang', ['sekarang'], 'now.svg'),
  'today': _SymbolSpec('Hari ini', ['hari ini'], 'today.svg'),
  'tomorrow': _SymbolSpec('Besok', ['besok'], 'tomorrow.svg'),
  'morning': _SymbolSpec('Pagi', ['pagi'], 'morning.svg'),
  'afternoon': _SymbolSpec('Siang', ['siang'], 'afternoon.svg'),
  'night': _SymbolSpec('Malam', ['malam'], 'night.svg'),

  // Tempat & benda.
  'school': _SymbolSpec('Sekolah', ['sekolah'], 'school.svg'),
  'car': _SymbolSpec('Mobil', ['mobil'], 'car.svg'),
  'ball': _SymbolSpec('Bola', ['bola'], 'ball.svg'),
  'music': _SymbolSpec('Musik', ['musik', 'lagu'], 'music.svg'),
  'computer': _SymbolSpec('Komputer', ['komputer', 'laptop'], 'computer_1.svg'),
  'clock': _SymbolSpec('Jam', ['jam', 'waktu'], 'clock.svg'),

  // Hewan.
  'dog': _SymbolSpec('Anjing', ['anjing'], 'dog.svg'),
  'cat': _SymbolSpec('Kucing', ['kucing'], 'cat.svg'),
  'bird': _SymbolSpec('Burung', ['burung'], 'bird.svg'),
  'cow': _SymbolSpec('Sapi', ['sapi'], 'cow.svg'),

  // Angka.
  'one': _SymbolSpec('Satu', ['satu', '1'], 'one.svg'),
  'two': _SymbolSpec('Dua', ['dua', '2'], 'two.svg'),
  'three': _SymbolSpec('Tiga', ['tiga', '3'], 'three.svg'),
};

String _encodeKeywords(List<String> keywords) =>
    '[${keywords.map((k) => '"$k"').join(',')}]';

/// Id simbol Mulberry deterministik (UUID v5) — perangkat mana pun
/// menghasilkan id yang sama, sehingga push sync tidak membuat
/// duplikat di server.
String mulberrySymbolId(String key) =>
    _uuid.v5(Namespace.url.value, 'https://aac-app/symbols/mulberry/$key');

/// Mengisi database dengan profile default, pustaka simbol Mulberry,
/// dan papan kosakata inti Bahasa Indonesia kalau masih kosong.
/// Mengembalikan id profile aktif.
Future<String> seedIfEmpty(AppDatabase db) async {
  final existing = await (db.select(db.profiles)
        ..where((p) => p.deletedAt.isNull())
        ..limit(1))
      .get();
  if (existing.isNotEmpty) return existing.first.id;

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
          const _CellSpec('Aku', colorPronoun, symbol: 'i'),
          const _CellSpec('Kamu', colorPronoun),
          const _CellSpec('Mau', colorVerb, symbol: 'want'),
          const _CellSpec('Tidak mau', colorNegation),
          const _CellSpec('Suka', colorVerb, symbol: 'good'),
          const _CellSpec('Tidak suka', colorNegation, symbol: 'bad'),
        ],
        [
          const _CellSpec('Makan', colorVerb, symbol: 'eat'),
          const _CellSpec('Minum', colorVerb, symbol: 'drink'),
          const _CellSpec('Main', colorVerb, symbol: 'play'),
          const _CellSpec('Tidur', colorVerb, symbol: 'sleep'),
          const _CellSpec('Toilet', colorNoun, symbol: 'toilet'),
          const _CellSpec('Tolong', colorSocial, symbol: 'help'),
        ],
        [
          const _CellSpec('Lagi', colorDescriptor, symbol: 'more'),
          const _CellSpec('Sudah', colorDescriptor, symbol: 'finish'),
          const _CellSpec('Ya', colorSocial, symbol: 'yes'),
          const _CellSpec('Tidak', colorNegation, symbol: 'no'),
          const _CellSpec('Sakit', colorDescriptor, symbol: 'sick'),
          const _CellSpec('Capek', colorDescriptor),
        ],
        [
          const _CellSpec('Senang', colorDescriptor, symbol: 'happy'),
          const _CellSpec('Sedih', colorDescriptor, symbol: 'sad'),
          const _CellSpec('Marah', colorDescriptor, symbol: 'angry'),
          const _CellSpec('Takut', colorDescriptor, symbol: 'afraid'),
          const _CellSpec('Halo', colorSocial, symbol: 'hello'),
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
          const _CellSpec('Nasi', colorNoun, symbol: 'rice'),
          const _CellSpec('Roti', colorNoun, symbol: 'bread'),
          const _CellSpec('Bubur', colorNoun, symbol: 'porridge'),
          const _CellSpec('Telur', colorNoun, symbol: 'egg'),
        ],
        [
          const _CellSpec('Ayam', colorNoun, symbol: 'chicken'),
          const _CellSpec('Ikan', colorNoun, symbol: 'fish'),
          const _CellSpec('Sayur', colorNoun, symbol: 'vegetables'),
          const _CellSpec('Buah', colorNoun, symbol: 'fruit'),
        ],
        [
          const _CellSpec('Pisang', colorNoun, symbol: 'banana'),
          const _CellSpec('Apel', colorNoun, symbol: 'apple'),
          const _CellSpec('Kue', colorNoun, symbol: 'cake'),
          const _CellSpec('Es krim', colorNoun, symbol: 'ice_cream'),
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
          const _CellSpec('Air putih', colorNoun, symbol: 'water'),
          const _CellSpec('Susu', colorNoun, symbol: 'milk'),
          const _CellSpec('Teh', colorNoun, symbol: 'tea'),
          const _CellSpec('Jus', colorNoun, symbol: 'orange_juice'),
        ],
        [
          const _CellSpec('Es teh', colorNoun, symbol: 'drink_cold'),
          const _CellSpec('Cokelat', colorNoun, symbol: 'hot_chocolate'),
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

    // Pustaka simbol Mulberry bawaan.
    final symbolIdByKey = <String, String>{};
    for (final entry in _mulberrySymbols.entries) {
      final id = mulberrySymbolId(entry.key);
      symbolIdByKey[entry.key] = id;
      final spec = entry.value;
      await db.into(db.symbols).insert(SymbolsCompanion.insert(
            id: id,
            pack: const Value('mulberry'),
            packRef: Value(spec.packRef),
            label: spec.label,
            keywords: Value(_encodeKeywords(spec.keywords)),
            imageUrl: Value('assets/symbols/mulberry/${entry.key}.svg'),
            license: const Value(_mulberryLicense),
          ));
    }

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
                symbolId: Value(
                  spec.symbol == null ? null : symbolIdByKey[spec.symbol],
                ),
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
