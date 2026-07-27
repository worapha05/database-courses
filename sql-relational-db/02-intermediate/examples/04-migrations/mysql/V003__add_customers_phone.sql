-- V003__add_customers_phone.sql (MySQL 8)

ALTER TABLE customers ADD COLUMN phone VARCHAR(32) NULL;


CREATE INDEX ix_mig_customers_phone ON customers (phone);


INSERT INTO schema_migrations (VERSION)
VALUES ('V003__add_customers_phone');
