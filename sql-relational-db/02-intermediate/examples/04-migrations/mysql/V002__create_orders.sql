-- V002__create_orders.sql (MySQL 8)

CREATE TABLE orders (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                                 customer_id BIGINT UNSIGNED NOT NULL,
                                                                             status VARCHAR(32) NOT NULL DEFAULT 'pending',
                                                                                                                 total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
                                                                                                                                                              ordered_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                                                                                                                                      PRIMARY KEY (id), CONSTRAINT fk_mig_orders_customer
                     FOREIGN KEY (customer_id) REFERENCES customers (id),
                                                          CONSTRAINT ck_mig_orders_status CHECK (status IN ('pending',
                                                                                                            'paid',
                                                                                                            'shipped',
                                                                                                            'cancelled')), CONSTRAINT ck_mig_orders_total_nonneg CHECK (total_amount >= 0)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE INDEX ix_mig_orders_customer_id ON orders (customer_id);


INSERT INTO schema_migrations (VERSION)
VALUES ('V002__create_orders');
