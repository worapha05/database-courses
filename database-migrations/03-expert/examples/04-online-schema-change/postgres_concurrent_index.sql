-- Build large indexes without long write locks (Postgres)
-- NOTE: CONCURRENTLY cannot run inside a transaction block.

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_accounts_email ON accounts (email);

-- Optional: validate constraint in two steps for some FK/CHECK patterns
--   1) ADD CONSTRAINT ... NOT VALID
--   2) VALIDATE CONSTRAINT ... (still takes locks; plan carefully)
 -- Observe blockers while DDL runs:
-- SELECT pid, state, wait_event_type, wait_event, query
-- FROM pg_stat_activity
-- WHERE datname = current_database() AND pid <> pg_backend_pid();
