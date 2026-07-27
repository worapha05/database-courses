-- =============================================================================
-- 01-relational-model / MySQL 8
-- ธีม: ร้านค้าออนไลน์ขนาดเล็ก — customers, products, orders, order_items
-- รัน: mysql ... bootcamp < 01_schema.sql
-- =============================================================================
SET NAMES utf8mb4;


SET FOREIGN_KEY_CHECKS = 0;


DROP TABLE IF EXISTS order_items;


DROP TABLE IF EXISTS orders;


DROP TABLE IF EXISTS products;


DROP TABLE IF EXISTS customers;


SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE customers (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                                    email VARCHAR(255) NOT NULL,
                                                                       full_name VARCHAR(150) NOT NULL,
                                                                                              created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                                                                      PRIMARY KEY (id), CONSTRAINT uq_customers_email UNIQUE (email)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE products (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                                   sku VARCHAR(64) NOT NULL,
                                                                   name VARCHAR(200) NOT NULL,
                                                                                     unit_price DECIMAL(12, 2) NOT NULL,
                                                                                                               is_active TINYINT(1) NOT NULL DEFAULT 1,
                                                                                                                                                     PRIMARY KEY (id), CONSTRAINT uq_products_sku UNIQUE (sku), CONSTRAINT ck_products_unit_price_nonneg CHECK (unit_price >= 0)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE orders
  (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                               customer_id BIGINT UNSIGNED NOT NULL,
                                                           status VARCHAR(32) NOT NULL DEFAULT 'pending',
                                                                                               ordered_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                                                                       PRIMARY KEY (id), CONSTRAINT fk_orders_customer
   FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT ON UPDATE CASCADE,
                                                                                    CONSTRAINT ck_orders_status CHECK (status IN ('pending',
                                                                                                                                  'paid',
                                                                                                                                  'shipped',
                                                                                                                                  'cancelled'))) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE order_items
  (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                               order_id BIGINT UNSIGNED NOT NULL,
                                                        product_id BIGINT UNSIGNED NOT NULL,
                                                                                   quantity INT NOT NULL,
                                                                                                unit_price DECIMAL(12, 2) NOT NULL,
                                                                                                                          PRIMARY KEY (id), CONSTRAINT fk_order_items_order
   FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE ON UPDATE CASCADE,
                                                                             CONSTRAINT fk_order_items_product
   FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT ON UPDATE CASCADE,
                                                                                  CONSTRAINT uq_order_items_order_product UNIQUE (order_id,
                                                                                                                                  product_id), CONSTRAINT ck_order_items_qty_positive CHECK (quantity > 0), CONSTRAINT ck_order_items_price_nonneg CHECK (unit_price >= 0)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE INDEX ix_orders_customer_id ON orders (customer_id);


CREATE INDEX ix_order_items_order_id ON order_items (order_id);


CREATE INDEX ix_order_items_product_id ON order_items (product_id);


INSERT INTO customers (email, full_name)
VALUES ('ann@example.com', 'Ann Tanaka'),
       ('ben@example.com', 'Ben Srisuk');


INSERT INTO products (sku, name, unit_price)
VALUES ('BOOK-001', 'SQL Foundations', 450.00),
       ('BOOK-002', 'PostgreSQL Internals', 890.00),
       ('STICKER-01', 'DB Sticker Pack', 59.00);


INSERT INTO orders (customer_id, status)
VALUES (1, 'paid'),
       (1, 'pending'),
       (2, 'paid');


INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (1, 1, 1, 450.00),
       (1, 3, 2, 59.00),
       (2, 2, 1, 890.00),
       (3, 1, 2, 450.00);


SELECT c.full_name,
       o.id AS order_id,
       o.status,
       p.name AS product,
       oi.quantity
FROM customers c
JOIN orders o ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id
ORDER BY o.id,
         oi.id;
