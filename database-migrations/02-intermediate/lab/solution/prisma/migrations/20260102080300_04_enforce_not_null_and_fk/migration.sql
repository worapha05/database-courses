DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM users
    WHERE first_name IS NULL OR last_name IS NULL OR status_id IS NULL
  ) THEN
    RAISE EXCEPTION 'Backfill incomplete — cannot enforce NOT NULL';
  END IF;
END $$;

ALTER TABLE "users"
  ALTER COLUMN "first_name" SET NOT NULL,
  ALTER COLUMN "last_name" SET NOT NULL,
  ALTER COLUMN "status_id" SET NOT NULL;

ALTER TABLE "users"
  ADD CONSTRAINT "users_status_id_fkey"
  FOREIGN KEY ("status_id") REFERENCES "user_statuses"("id")
  ON DELETE RESTRICT ON UPDATE CASCADE;
