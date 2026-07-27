-- V003__add_customers_phone.sql (PostgreSQL)
-- Expand/Contract: เพิ่มคอลัมน์ nullable ก่อน — แอปค่อยบังคับทีหลัง

ALTER TABLE customers ADD COLUMN phone VARCHAR(32);


CREATE INDEX ix_mig_customers_phone ON customers (phone);


INSERT INTO schema_migrations (VERSION)
VALUES ('V003__add_customers_phone');
