-- V002__create_orders.sql (PostgreSQL)

CREATE TABLE orders (id BIGSERIAL PRIMARY KEY,
                                  customer_id BIGINT NOT NULL,
                                                     status VARCHAR(32) NOT NULL DEFAULT 'pending',
                                                                                         total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
                                                                                                                                      ordered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                                                                                                                                                              CONSTRAINT fk_mig_orders_customer
                     FOREIGN KEY (customer_id) REFERENCES customers (id),
                                                          CONSTRAINT ck_mig_orders_status CHECK (status IN ('pending',
                                                                                                            'paid',
                                                                                                            'shipped',
                                                                                                            'cancelled')), CONSTRAINT ck_mig_orders_total_nonneg CHECK (total_amount >= 0));


CREATE INDEX ix_mig_orders_customer_id ON orders (customer_id);


INSERT INTO schema_migrations (VERSION)
VALUES ('V002__create_orders');
