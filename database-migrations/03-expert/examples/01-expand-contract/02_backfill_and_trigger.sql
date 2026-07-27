-- Backfill existing rows

UPDATE accounts
SET display_name = full_name
WHERE display_name IS NULL
  AND full_name IS NOT NULL;

-- Dual-write trigger so old writers keep new column warm

CREATE OR REPLACE FUNCTION accounts_sync_display_name() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.display_name IS NULL AND NEW.full_name IS NOT NULL THEN
    NEW.display_name := NEW.full_name;
  ELSIF NEW.full_name IS NULL AND NEW.display_name IS NOT NULL THEN
    NEW.full_name := NEW.display_name;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.full_name IS DISTINCT FROM OLD.full_name
       AND NEW.display_name IS NOT DISTINCT FROM OLD.display_name
    THEN
      NEW.display_name := NEW.full_name;
    ELSIF NEW.display_name IS DISTINCT FROM OLD.display_name
           AND NEW.full_name IS NOT DISTINCT FROM OLD.full_name
    THEN
      NEW.full_name := NEW.display_name;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;


DROP TRIGGER IF EXISTS trg_accounts_sync_display_name ON accounts;


CREATE TRIGGER trg_accounts_sync_display_name
BEFORE
INSERT
OR
UPDATE ON accounts
FOR EACH ROW EXECUTE PROCEDURE accounts_sync_display_name();
