DROP INDEX IF EXISTS symbols_category_idx;
ALTER TABLE symbols DROP COLUMN IF EXISTS category;
