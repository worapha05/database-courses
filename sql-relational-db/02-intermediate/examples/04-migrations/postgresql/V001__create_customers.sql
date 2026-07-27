-- V001__create_customers.sql (PostgreSQL)
-- หมายเหตุ: migration จริงไม่ใช้ IF NOT EXISTS — รันครั้งเดียวต่อ environment
-- แล้วให้ schema_migrations บันทึกว่า apply แล้ว

CREATE TABLE schema_migrations (VERSION VARCHAR(64) PRIMARY KEY,
                                                    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW());


CREATE TABLE customers (id BIGSERIAL PRIMARY KEY,
                                     email VARCHAR(255) NOT NULL,
                                                        full_name VARCHAR(150) NOT NULL,
                                                                               created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                                                                                                       CONSTRAINT uq_mig_customers_email UNIQUE (email));


INSERT INTO schema_migrations (VERSION)
VALUES ('V001__create_customers');
