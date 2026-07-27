-- Baseline legacy table for the lab (if starting empty)
CREATE TABLE IF NOT EXISTS "users" (
  "id" SERIAL PRIMARY KEY,
  "full_name" TEXT NOT NULL,
  "email" TEXT NOT NULL UNIQUE,
  "phone" TEXT,
  "status" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE "user_statuses" (
  "id" SERIAL PRIMARY KEY,
  "code" VARCHAR(32) NOT NULL UNIQUE,
  "label" TEXT NOT NULL
);

INSERT INTO
  "user_statuses" ("code", "label")
VALUES
  ('active', 'Active'),
  ('disabled', 'Disabled'),
  ('banned', 'Banned');
