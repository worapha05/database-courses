-- Branch A (resolved timestamp)

ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "avatar_url" TEXT;
