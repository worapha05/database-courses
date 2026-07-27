-- Approximate shape of Knex history + lock tables (tool-managed).

CREATE TABLE IF NOT EXISTS knex_migrations (id SERIAL PRIMARY KEY,
                                                      name VARCHAR(255),
                                                           batch INTEGER, migration_time TIMESTAMPTZ);


CREATE TABLE IF NOT EXISTS knex_migrations_lock (INDEX INTEGER PRIMARY KEY,
                                                               is_locked INTEGER);


INSERT INTO knex_migrations_lock (INDEX, is_locked)
VALUES (1, 0) ON CONFLICT (INDEX) DO NOTHING;

-- SELECT id, name, batch, migration_time FROM knex_migrations ORDER BY id;
