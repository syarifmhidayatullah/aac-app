-- Berbagi papan antar akun via kode singkat berumur pendek.
-- Impor MENYALIN papan (bukan referensi), jadi share hanya perlu
-- menunjuk papan sumber selama kodenya berlaku.
CREATE TABLE board_shares (
    code       text PRIMARY KEY,
    board_id   uuid NOT NULL REFERENCES boards (id) ON DELETE CASCADE,
    created_by uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL
);

CREATE INDEX board_shares_board_id_idx ON board_shares (board_id);
