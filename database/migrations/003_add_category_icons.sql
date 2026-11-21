BEGIN IMMEDIATE;

ALTER TABLE categories
ADD COLUMN icon_key TEXT NOT NULL DEFAULT 'category'
    CHECK (length(trim(icon_key)) > 0);

UPDATE categories
SET icon_key = CASE id
    WHEN 'utilities' THEN 'bolt'
    WHEN 'entertainment' THEN 'movie'
    ELSE 'category'
END;

PRAGMA user_version = 3;

COMMIT;
