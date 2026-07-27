-- Step 3 (Constrain): only after verification passes
-- Fail fast if nulls remain
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM users WHERE phone IS NULL) THEN
    RAISE EXCEPTION 'Cannot enforce NOT NULL: users.phone still has NULL values';
  END IF;
END $$;


ALTER TABLE users
ALTER COLUMN phone
SET NOT NULL;
