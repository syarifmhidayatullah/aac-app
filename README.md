# AAC App

Aplikasi Augmentative and Alternative Communication (AAC) — papan simbol
dengan text-to-speech untuk membantu komunikasi, target utama iPad
(plus Android & web via Flutter).

## Struktur

- `backend/` — REST API (Go + chi), PostgreSQL
- `frontend/` — Flutter (iOS/iPad, Android, web)
- `docker-compose.yml` — PostgreSQL untuk development

## Menjalankan (development)

```sh
# Database
docker compose up -d postgres

# Backend
cd backend
cp .env.example .env
go run ./cmd/server

# Frontend
cd frontend
flutter run
```

## Arsitektur

Offline-first: aplikasi menyimpan papan & simbol secara lokal (SQLite)
dan tetap berfungsi penuh tanpa internet (termasuk TTS via engine
native). Backend dipakai untuk akun, sinkronisasi antar perangkat,
berbagi papan, dan penyimpanan gambar custom.

Pustaka simbol: [ARASAAC](https://arasaac.org) (lisensi CC BY-NC-SA).
