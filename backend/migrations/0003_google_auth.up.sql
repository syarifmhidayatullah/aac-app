-- Dukungan login Google: user bisa tanpa password (Google-only),
-- google_id = klaim `sub` dari ID token Google (stabil per akun).
ALTER TABLE users
    ALTER COLUMN password_hash DROP NOT NULL,
    ADD COLUMN google_id text UNIQUE,
    ADD COLUMN avatar_url text;
