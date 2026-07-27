-- V004__add_orders_status_index.sql (PostgreSQL)
-- บน prod จริงอาจใช้: CREATE INDEX CONCURRENTLY (รันนอก transaction)

CREATE INDEX ix_mig_orders_status_ordered_at ON orders (status, ordered_at DESC);


INSERT INTO schema_migrations (VERSION)
VALUES ('V004__add_orders_status_index');
