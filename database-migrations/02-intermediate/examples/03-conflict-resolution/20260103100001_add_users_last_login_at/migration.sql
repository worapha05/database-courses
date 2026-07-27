-- Branch B — renamed to avoid colliding with A after merge

ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "last_login_at" TIMESTAMPTZ;
