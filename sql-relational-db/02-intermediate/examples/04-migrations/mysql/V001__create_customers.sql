-- V001__create_customers.sql (MySQL 8)
-- หมายเหตุ: migration จริงไม่ใช้ IF NOT EXISTS — รันครั้งเดียวต่อ environment

CREATE TABLE schema_migrations (VERSION VARCHAR(64) NOT NULL,
                                                    applied_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                            PRIMARY KEY (VERSION)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE customers (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                                    email VARCHAR(255) NOT NULL,
                                                                       full_name VARCHAR(150) NOT NULL,
                                                                                              created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                                                                      PRIMARY KEY (id), CONSTRAINT uq_mig_customers_email UNIQUE (email)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


INSERT INTO schema_migrations (VERSION)
VALUES ('V001__create_customers');
