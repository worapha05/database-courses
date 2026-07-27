-- EXPAND: additive, old app keeps using full_name

ALTER TABLE accounts ADD COLUMN IF NOT EXISTS display_name TEXT;

COMMENT ON COLUMN accounts.display_name IS 'Expanded column; dual-write with full_name until contract';
