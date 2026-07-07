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
- Database Postgres di-host di Railway; env `DATABASE_URL` diambil dari
  service Postgres Railway (variable reference).
- **Migrasi otomatis**: server menjalankan semua migrasi pending
  (golang-migrate, embedded via `embed.FS`) saat startup, sebelum listen.
  Jadi DDL baru cukup ditambahkan sebagai file migrasi → push → tereksekusi.
- Service Railway harus di-set **Root Directory = `backend/`**
  (build pakai `backend/Dockerfile`, config di `backend/railway.json`).
- Env wajib: `DATABASE_URL`, `JWT_SECRET`. Opsional: `GOOGLE_CLIENT_IDS`
  (login Google), `ALLOWED_ORIGINS`, `TOKEN_TTL`, `UPLOAD_DIR`.
- Upload gambar tersimpan di filesystem — di Railway WAJIB mount
  **Volume** (mis. ke `/data`) dan set `UPLOAD_DIR=/data/uploads`,
  kalau tidak file hilang tiap deploy.
- Jika koneksi internal Railway menolak SSL, tambahkan `?sslmode=disable`
  ke `DATABASE_URL`.

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
5. ⬜ **Editor papan** — mode edit caregiver: tambah/ubah sel, pilih
   simbol dari pustaka/foto sendiri, atur ukuran grid, parental gate.
6. ⬜ **Sync & akun** — login di Flutter, sinkronisasi dua arah,
   berbagi papan antar akun.
7. ⬜ **Polish** — layout iPad landscape, aksesibilitas (tap target,
   kontras), pengaturan suara/kecepatan TTS, build web & Android, testing.

## TODO sisi user (tidak bisa dikerjakan Claude)

- [ ] Buat repo GitHub + push pertama (commit belum pernah dibuat).
- [ ] Railway: project + service Postgres + service repo (Root Directory
  = `backend`), env `DATABASE_URL` (reference), `JWT_SECRET`,
  Volume di `/data` + `UPLOAD_DIR=/data/uploads`.
- [ ] Google Cloud Console: OAuth Client ID (iOS/Android/Web) →
  env `GOOGLE_CLIENT_IDS` (dipisah koma) untuk login Google.

## Catatan lingkungan dev

- Mac pertama (id00242): Flutter di `~/development/flutter`; per
  2026-07-07 sedang di-upgrade dari 3.7.7 ke stable terbaru (3.44).
  Kalau flutter command menggantung, pakai `--no-version-check`.
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
