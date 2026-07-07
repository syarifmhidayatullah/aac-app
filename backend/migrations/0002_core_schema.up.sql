-- Skema inti AAC: users → profiles → boards → cells, plus pustaka symbols.
-- Semua tabel data punya updated_at (trigger) + deleted_at (soft delete)
-- untuk sinkronisasi berbasis timestamp; UUID boleh di-generate klien.

CREATE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Akun caregiver/terapis (yang login), bukan pengguna AAC itu sendiri.
CREATE TABLE users (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email         citext NOT NULL UNIQUE,
    password_hash text NOT NULL,
    display_name  text NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER users_set_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Pengguna AAC; satu akun bisa punya beberapa (mis. terapis dengan
-- beberapa klien). settings: suara/kecepatan TTS, ukuran grid, dsb.
CREATE TABLE profiles (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name       text NOT NULL,
    settings   jsonb NOT NULL DEFAULT '{}',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz
);

CREATE INDEX profiles_user_id_idx ON profiles (user_id);
CREATE INDEX profiles_updated_at_idx ON profiles (updated_at);

CREATE TRIGGER profiles_set_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Pustaka simbol. owner_user_id NULL = simbol bawaan sebuah pack
-- (mis. Mulberry); selain itu upload custom milik user.
CREATE TABLE symbols (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id uuid REFERENCES users (id) ON DELETE CASCADE,
    pack          text NOT NULL DEFAULT 'custom',
    pack_ref      text,
    label         text NOT NULL,
    keywords      text[] NOT NULL DEFAULT '{}',
    image_url     text,
    license       text,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    deleted_at    timestamptz
);

CREATE INDEX symbols_owner_user_id_idx ON symbols (owner_user_id);
CREATE INDEX symbols_pack_idx ON symbols (pack);
CREATE INDEX symbols_keywords_idx ON symbols USING gin (keywords);
CREATE INDEX symbols_updated_at_idx ON symbols (updated_at);

CREATE TRIGGER symbols_set_updated_at
    BEFORE UPDATE ON symbols
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Papan simbol; satu profile punya tepat satu papan root (halaman utama).
CREATE TABLE boards (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    name       text NOT NULL,
    grid_rows  int NOT NULL DEFAULT 4 CHECK (grid_rows BETWEEN 1 AND 12),
    grid_cols  int NOT NULL DEFAULT 6 CHECK (grid_cols BETWEEN 1 AND 12),
    is_root    boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz
);

CREATE INDEX boards_profile_id_idx ON boards (profile_id);
CREATE INDEX boards_updated_at_idx ON boards (updated_at);
CREATE UNIQUE INDEX boards_one_root_per_profile_uq
    ON boards (profile_id) WHERE is_root AND deleted_at IS NULL;

CREATE TRIGGER boards_set_updated_at
    BEFORE UPDATE ON boards
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Sel grid. action 'speak' mengucapkan speak_text (fallback: label);
-- action 'navigate' membuka target_board_id. Validasi "navigate wajib
-- punya target" dilakukan di app layer, bukan CHECK, supaya
-- ON DELETE SET NULL tidak pernah bentrok dengan constraint.
CREATE TABLE cells (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    board_id         uuid NOT NULL REFERENCES boards (id) ON DELETE CASCADE,
    row_index        int NOT NULL CHECK (row_index >= 0),
    col_index        int NOT NULL CHECK (col_index >= 0),
    label            text NOT NULL,
    speak_text       text,
    symbol_id        uuid REFERENCES symbols (id) ON DELETE SET NULL,
    background_color text,
    action_type      text NOT NULL DEFAULT 'speak'
                     CHECK (action_type IN ('speak', 'navigate')),
    target_board_id  uuid REFERENCES boards (id) ON DELETE SET NULL,
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now(),
    deleted_at       timestamptz
);

CREATE INDEX cells_board_id_idx ON cells (board_id);
CREATE INDEX cells_updated_at_idx ON cells (updated_at);
CREATE UNIQUE INDEX cells_position_uq
    ON cells (board_id, row_index, col_index) WHERE deleted_at IS NULL;

CREATE TRIGGER cells_set_updated_at
    BEFORE UPDATE ON cells
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
