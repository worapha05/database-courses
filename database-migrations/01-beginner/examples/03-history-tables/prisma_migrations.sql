-- Approximate shape of Prisma's history table (tool-managed).
-- Do not create/alter this manually in real projects.

CREATE TABLE IF NOT EXISTS "_prisma_migrations" ("id" VARCHAR(36) PRIMARY KEY,
                                                                  "checksum" VARCHAR(64) NOT NULL,
                                                                                         "finished_at" TIMESTAMPTZ,
                                                                                         "migration_name" VARCHAR(255) NOT NULL,
                                                                                                                       "logs" TEXT, "rolled_back_at" TIMESTAMPTZ,
                                                                                                                                    "started_at" TIMESTAMPTZ NOT NULL DEFAULT now(),
                                                                                                                                                                              "applied_steps_count" INTEGER NOT NULL DEFAULT 0);

-- Useful inspection queries
-- SELECT migration_name, checksum, finished_at, rolled_back_at
-- FROM "_prisma_migrations"
-- ORDER BY started_at;
