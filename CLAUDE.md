# AAC App

Aplikasi AAC (Augmentative and Alternative Communication): papan simbol +
text-to-speech untuk membantu komunikasi (mirip Proloquo2Go). Target utama
**iPad**, plus Android & web — semuanya dari satu codebase Flutter.

Bahasa komunikasi dengan user: **Bahasa Indonesia**.
Cara kerja: eksekusi **satu fase**, lalu **berhenti dan konfirmasi user**
sebelum lanjut ke fase berikutnya.

## Struktur

- `backend/` — Go (chi router), PostgreSQL. Module:
  `github.com/syarifhidayatullah/aac-app/backend`
- `frontend/` — Flutter (`aac_app`, org `com.aacapp`, platform ios/android/web)
- `docker-compose.yml` — Postgres lokal (opsional; Docker TIDAK terinstal
  di mesin dev, DB utama di-host di Railway)

## Deployment (Railway)

- Push ke GitHub → Railway auto-deploy backend.
- Database Postgres di-host di **Supabase** (bukan Railway Postgres);
  config dibangun dari env `DB_HOST/DB_PORT/DB_USER/DB_PASSWORD/DB_NAME/
  DB_SSLMODE` terpisah (`internal/config/config.go` merakitnya jadi DSN
  `postgres://...`), bukan satu `DATABASE_URL` utuh.
  **Pakai Session Pooler Supabase** (`aws-0-<region>.pooler.supabase.com`,
  port `5432`, user `postgres.<project-ref>`) — BUKAN Direct connection
  (`db.<ref>.supabase.co`, IPv6-only, `network is unreachable` dari
  Railway) dan BUKAN Transaction pooler (port `6543`, tidak mendukung
  advisory lock yang dipakai `golang-migrate`).
- **Migrasi otomatis**: server menjalankan semua migrasi pending
  (golang-migrate, embedded via `embed.FS`) saat startup, sebelum listen.
  Jadi DDL baru cukup ditambahkan sebagai file migrasi → push → tereksekusi.
- Service Railway harus di-set **Root Directory = `backend/`**
  (build pakai `backend/Dockerfile`, config di `backend/railway.json`).
- Env wajib: `DB_HOST`, `JWT_SECRET`. Opsional: `DB_PORT` (default 5432),
  `DB_USER` (default postgres), `DB_PASSWORD`, `DB_NAME` (default postgres),
  `DB_SSLMODE` (default require), `GOOGLE_CLIENT_IDS` (login Google),
  `ALLOWED_ORIGINS`, `TOKEN_TTL`, `UPLOAD_DIR`.
- Upload gambar tersimpan di filesystem — di Railway WAJIB mount
  **Volume** (mis. ke `/data`) dan set `UPLOAD_DIR=/data/uploads`,
  kalau tidak file hilang tiap deploy. (Supabase tidak punya volume
  setara — hanya object storage terpisah, butuh ubah kode kalau mau
  dipakai.)

## Konvensi

- Migrasi: `backend/migrations/NNNN_nama.up.sql` + `.down.sql`
  (nomor urut 4 digit). Jangan pernah mengedit migrasi yang sudah ter-push;
  selalu buat file baru.
- Arsitektur backend: `cmd/server` (entrypoint),
  `internal/{handler,service,repository,model,middleware}`.
- Flutter di mesin ini: SELALU pakai `flutter --no-version-check <cmd>` —
  cek update flutter menggantung di SSH github.

## Perintah

```sh
# Backend
cd backend && go build ./... && go test ./...
go run ./cmd/server            # butuh .env atau env vars (lihat .env.example)

# Frontend
cd frontend && flutter --no-version-check run
flutter --no-version-check analyze
```

## Rencana (7 fase)

1. ✅ **Fondasi** — struktur direktori, Go module + chi + `/health`,
   flutter create, docker-compose, git init. (Selesai 2026-07-07)
2. ✅ **Skema DB & migrasi** — golang-migrate embedded + auto-run saat
   startup; migrasi `0002_core_schema`: `users` (caregiver/terapis),
   `profiles` (pengguna AAC, >1 per akun), `boards` (root unik per
   profile), `cells` (posisi row/col, aksi speak/navigate), `symbols`
   (pack Mulberry/custom, keywords GIN). Semua dengan trigger
   `updated_at` + soft delete. Diverifikasi test embedded-postgres
   (`internal/db/migrate_test.go`; skip dengan `-short`).
   (Selesai 2026-07-07)
3. ✅ **Backend API** — auth JWT: register/login + **login Google**
   (`POST /auth/google` menerima ID token dari Google Sign-In klien,
   diverifikasi via `google.golang.org/api/idtoken` + cek audience ke
   `GOOGLE_CLIENT_IDS`; auto-link ke akun ber-email sama yang verified).
   CRUD profiles/boards/cells/symbols (ownership dicek per query),
   `PUT /boards/{id}/cells` mengganti grid atomik, upload gambar
   (sniff content-type, nama UUID), sync pull/push (`GET/POST /sync`,
   tombstone + last-push-wins), profile baru otomatis dapat papan seed
   kosakata inti Bahasa Indonesia (warna Fitzgerald key, 4x6).
   Semua endpoint di `/api/v1`. Integration test end-to-end:
   `internal/handler/api_test.go`. (Selesai 2026-07-07)
4. ✅ **Flutter inti** — `lib/data/db.dart` (drift:
   Profiles/Boards/Cells/Symbols, mirror skema server + kolom `dirty`
   untuk sync Fase 6; codegen `db.g.dart` via build_runner),
   `lib/data/seed.dart` (papan utama 5x6 = 24 kosakata inti + 2 sel
   navigasi ke papan Makanan 3x4 & Minuman 2x4),
   `lib/data/board_repository.dart`, `lib/services/speech_service.dart`
   (abstraksi SpeechService + impl flutter_tts id-ID, fake-able di
   test), `lib/state/communication_state.dart` (ChangeNotifier: board
   stack, sentence strip, tapCell speak/navigate), `lib/ui/`
   (Material 3, grid + sentence strip). 6 unit test pass
   (`test/communication_test.dart`, drift in-memory + FakeSpeech),
   analyzer bersih, `flutter build web` sukses. Flutter di-upgrade
   3.7.7 → 3.44.5. BELUM diuji di device/simulator nyata (suara TTS
   & rasa UI perlu dicoba manual di iPad/simulator).
   (Selesai 2026-07-07)
5. ✅ **Editor papan** — parental gate (soal perkalian,
   `lib/ui/widgets/parental_gate.dart`) dari ikon pensil di layar
   komunikasi → `BoardEditorScreen` (`lib/ui/editor/`): grid dengan
   slot kosong "+", tap sel → `cell_editor_sheet.dart` (label, teks
   ucapan, 8 warna Fitzgerald, aksi ucapkan/buka papan + buat papan
   baru, hapus sel = soft delete), pengaturan papan (nama + grid
   maks 8x10; sel di luar grid disembunyikan, tidak dihapus), dropdown
   pindah papan. Pemilih simbol (`symbol_picker.dart`): cari pustaka
   lokal + foto kamera/galeri (image_picker; izin di Info.plist;
   `ImageStore`: file di documents/images dengan path RELATIF di DB,
   data URI base64 di web). Pustaka bawaan: 38 SVG **Mulberry**
   di-bundle (`assets/symbols/mulberry/` + ATTRIBUTION.md, CC BY-SA
   2.0 UK) di-seed dengan label/keyword Indonesia + tertaut ke sel
   seed; render via flutter_svg (`SymbolImage` menangani assets/,
   data:, http, path relatif). BoardRepository dapat operasi tulis
   (upsert/delete cell, create/update board, search/create symbol) —
   semua set `dirty` + `updatedAt` untuk sync Fase 6. 15 unit test
   pass, analyzer bersih, build web sukses. BELUM diuji di
   device/simulator nyata. (Selesai 2026-07-07)
6. ✅ **Sync & akun** — Backend: berbagi papan via kode 8-char
   (migrasi `0004_board_shares`, `POST /boards/{id}/share` → kode
   berlaku 7 hari, `POST /boards/import` {code, profile_id} MENYALIN
   board+cells, simbol milik pembagi ikut disalin ke pengimpor,
   target navigasi di-strip). Flutter: `ApiClient`
   (`lib/services/api_client.dart`; base URL dari `--dart-define
   AAC_API_URL` / bisa diubah di UI), `SyncService`
   (`lib/services/sync_service.dart`): first-sync = server ada data →
   REPLACE lokal (ganti profile aktif), server kosong → push seluruh
   seed; sync rutin = upload foto custom (imageUrl lokal ditukar URL
   server) → push baris dirty → mark clean → pull since → apply
   (tombstone ikut). Id simbol Mulberry = UUID v5 deterministik
   (`mulberrySymbolId`) supaya tidak duplikat antar perangkat.
   `AccountState` (`lib/state/account_state.dart`, sesi di
   shared_preferences; logout mempertahankan data lokal) +
   `AccountScreen` di balik parental gate (ikon profil): login/daftar,
   sinkronkan sekarang, impor papan dengan kode, logout. Tombol
   bagikan (ios_share) di editor: sync dulu lalu tampilkan kode.
   Go test pass (incl. share/import), 23 unit test Flutter pass,
   analyzer bersih, build web sukses. BELUM diuji end-to-end lawan
   server sungguhan dari app (perlu Railway/lokal + 2 device).
   (Selesai 2026-07-07)
7. ✅ **Polish** — Grid papan responsif (`BoardGridLayout`,
   `lib/ui/widgets/board_grid.dart`): rasio sel dihitung dari layar,
   papan mengisi penuh tanpa scroll (portrait & landscape iPad),
   dipakai layar komunikasi + editor. Aksesibilitas: MergeSemantics di
   CellTile + semanticLabel folder. Pengaturan suara TTS per profile
   (kecepatan + pitch, slider + tombol coba,
   `lib/ui/editor/voice_settings_dialog.dart` dari appbar editor),
   tersimpan di `profiles.settings` JSON (`tts_rate`/`tts_pitch`,
   dirty → ikut sync), diterapkan saat load
   (`CommunicationState.applySpeechSettings`);
   `SpeechService.configure(rate, pitch)`. SVG Mulberry di-preprocess:
   CSS `<style>` di-inline ke atribut (flutter_svg tak mendukung
   `<style>` — tadinya siluet hitam). Atribusi Mulberry tampil di
   AccountScreen. Android: folder `android/` DI-REGENERATE dengan
   template Flutter 3.44 (yang lama Gradle imperatif 3.7 → build
   gagal); INTERNET permission + label AAC di manifest;
   `CFBundleDisplayName` iOS = AAC. Build web ✓, build apk --debug ✓.
   27 test pass (unit + widget: papan, folder, parental gate),
   analyzer bersih. Testing di device/simulator nyata + rilis
   bertanda tangan (signing) BELUM. (Selesai 2026-07-07)

**Pasca-Fase 7 (2026-07-19):**
- Diuji di iPad fisik pertama kali (Mac dev + Xcode 26.6, JDK 17,
  iOS platform component 26.5). Fix: `ios/Podfile` sempat referensikan
  target `RunnerTests` yang nggak ada di project (dihapus), gerbang
  orang tua diganti dari `TextField` + keyboard sistem ke keypad angka
  custom (keyboard on-screen iOS kadang nggak muncul lagi setelah
  ditutup manual di iPad — bug dikenal Flutter, keypad custom
  menghindarinya sepenuhnya).
- Pustaka simbol Mulberry diperluas dari 38 → **98 simbol** (`lib/data/seed.dart`,
  `assets/symbols/mulberry/`). 60 simbol baru (keluarga, kata kerja,
  warna, konsep, kata tanya, waktu, tempat/benda, hewan, angka)
  **hanya tersedia lewat pencarian di symbol picker** — sengaja TIDAK
  dipasang ke papan bawaan manapun (papan utama/Makanan/Minuman tetap
  seperti Fase 4). Sumber tetap Mulberry Symbols (CC BY-SA 2.0 UK,
  `EN/` di repo `mulberrysymbols/mulberry-symbols`), di-preprocess
  CSS-inline yang sama (banyak file source pakai `<style>` class rules
  yang tidak didukung flutter_svg).

## TODO sisi user (tidak bisa dikerjakan Claude)

- [x] Buat repo GitHub + push pertama.
- [ ] Railway: service repo (Root Directory = `backend`), env
  `DB_HOST/DB_PORT/DB_USER/DB_PASSWORD/DB_NAME/DB_SSLMODE` (dari
  Supabase Session Pooler), `JWT_SECRET`, Volume di `/data` +
  `UPLOAD_DIR=/data/uploads`.
- [ ] Google Cloud Console: OAuth Client ID (iOS/Android/Web) →
  env `GOOGLE_CLIENT_IDS` (dipisah koma) untuk login Google.

## Catatan lingkungan dev

- Mac pertama (id00242): Flutter di `~/development/flutter`; per
  2026-07-07 sedang di-upgrade dari 3.7.7 ke stable terbaru (3.44).
  Kalau flutter command menggantung, pakai `--no-version-check`.
- Build Android butuh JDK 17: `brew install openjdk@17` lalu
  `flutter config --jdk-dir=/opt/homebrew/opt/openjdk@17`
  (Android Studio lama cuma bundel JBR 11). Sudah di-set di Mac kedua
  (syarifs-air) 2026-07-07.
- Laptop lain: cukup clone repo — CLAUDE.md ini adalah sumber
  kebenaran status proyek. Pastikan Flutter stable terbaru (Dart ≥3.5)
  dan Go ≥1.24.

## Keputusan arsitektur

- **Offline-first**: app harus berfungsi penuh tanpa internet (termasuk
  TTS via engine native). Backend hanya untuk akun, sync antar perangkat,
  berbagi papan, dan penyimpanan gambar custom.
- **App akan dijual (komersial)** → pustaka simbol default:
  **Mulberry Symbols** (3.436 SVG, CC BY-SA — boleh komersial dengan
  atribusi). ARASAAC (13.800 piktogram) TIDAK dipakai: lisensinya
  CC BY-NC-SA (non-komersial) dan API-nya tidak mendukung locale `id`.
  Label/keyword Bahasa Indonesia dikurasi sendiri untuk subset simbol
  yang dipakai papan bawaan. Layer simbol pluggable (kolom `pack` +
  `license` di tabel `symbols`); foto/gambar custom pengguna menambal
  celah kosakata.
- **Sync**: timestamp-based — semua tabel data punya `updated_at`
  (di-set trigger) + soft delete `deleted_at`; klien generate UUID
  sendiri (offline), pull perubahan dengan `WHERE updated_at > since`.
