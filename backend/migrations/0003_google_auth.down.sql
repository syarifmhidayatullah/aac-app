ALTER TABLE users
    DROP COLUMN avatar_url,
    DROP COLUMN google_id,
    ALTER COLUMN password_hash SET NOT NULL;
