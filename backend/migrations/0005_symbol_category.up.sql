-- Kategori simbol (mis. "keluarga", "kata kerja", "warna") untuk
-- browsing per kategori di symbol picker. Nullable — simbol custom
-- foto pengguna tidak wajib punya kategori.
ALTER TABLE symbols ADD COLUMN category text;
CREATE INDEX symbols_category_idx ON symbols (category);
