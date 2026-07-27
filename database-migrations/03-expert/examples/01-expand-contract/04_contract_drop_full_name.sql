-- CONTRACT: only after old app versions are gone

DROP TRIGGER IF EXISTS trg_accounts_sync_display_name ON accounts;


DROP FUNCTION IF EXISTS accounts_sync_display_name();


ALTER TABLE accounts
ALTER COLUMN display_name
SET NOT NULL;


ALTER TABLE accounts
DROP COLUMN IF EXISTS full_name;
