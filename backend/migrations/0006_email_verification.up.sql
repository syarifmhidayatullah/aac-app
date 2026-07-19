-- Verifikasi email untuk akun email/password. Akun Google dianggap
-- terverifikasi otomatis (Google sudah verifikasi email-nya).
ALTER TABLE users ADD COLUMN is_verified boolean NOT NULL DEFAULT false;

-- Akun yang sudah ada sebelum fitur ini jangan sampai terkunci.
UPDATE users SET is_verified = true;

CREATE TABLE email_verifications (
    token      text PRIMARY KEY,
    user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    expires_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX email_verifications_user_id_idx ON email_verifications (user_id);
