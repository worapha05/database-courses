-- Step 1 (Expand): additive, non-breaking for old app versions

ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(32) NULL;

-- Optional: keep writing to legacy "mobile" while dual-writing in app
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS mobile VARCHAR(32);
