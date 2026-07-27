-- =============================================================================
-- 04-normalization / MySQL 8
-- แปลงจากตาราง denormalized (0NF) → 1NF → 2NF → 3NF
-- =============================================================================
SET NAMES utf8mb4;


DROP TABLE IF EXISTS messy_orders;


CREATE TABLE messy_orders (order_no VARCHAR(20),
                                    customer_name VARCHAR(150),
                                                  customer_city VARCHAR(100),
                                                                customer_zip VARCHAR(20),
                                                                             products TEXT, total_amount DECIMAL(12, 2)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


INSERT INTO messy_orders
VALUES ('ORD-1', 'Ann', 'Bangkok', '10110', 'BOOK-001 x1, STICKER-01 x2', 568.00),
       ('ORD-2', 'Ann', 'Bangkok', '10110', 'BOOK-002 x1', 890.00),
       ('ORD-3', 'Ben', 'Chiang Mai', '50200', 'BOOK-001 x2', 900.00);


DROP TABLE IF EXISTS orders_1nf;


CREATE TABLE orders_1nf (order_no VARCHAR(20) NOT NULL,
                                              customer_name VARCHAR(150) NOT NULL,
                                                                         customer_city VARCHAR(100) NOT NULL,
                                                                                                    customer_zip VARCHAR(20) NOT NULL,
                                                                                                                             product_sku VARCHAR(64) NOT NULL,
                                                                                                                                                     quantity INT NOT NULL,
                                                                                                                                                                  line_amount DECIMAL(12, 2) NOT NULL,
                                                                                                                                                                                             PRIMARY KEY (order_no,
                                                                                                                                                                                                          product_sku)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


INSERT INTO orders_1nf
VALUES ('ORD-1', 'Ann', 'Bangkok', '10110', 'BOOK-001', 1, 450.00),
       ('ORD-1', 'Ann', 'Bangkok', '10110', 'STICKER-01', 2, 118.00),
       ('ORD-2', 'Ann', 'Bangkok', '10110', 'BOOK-002', 1, 890.00),
       ('ORD-3', 'Ben', 'Chiang Mai', '50200', 'BOOK-001', 2, 900.00);


SET FOREIGN_KEY_CHECKS = 0;


DROP TABLE IF EXISTS norm_order_items;


DROP TABLE IF EXISTS norm_orders;


DROP TABLE IF EXISTS norm_products;


DROP TABLE IF EXISTS norm_customers;


SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE norm_customers (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                                         full_name VARCHAR(150) NOT NULL,
                                                                                city VARCHAR(100) NOT NULL,
                                                                                                  zip_code VARCHAR(20) NOT NULL,
                                                                                                                       PRIMARY KEY (id)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE norm_products (sku VARCHAR(64) NOT NULL,
                                            name VARCHAR(200) NOT NULL,
                                                              unit_price DECIMAL(12, 2) NOT NULL,
                                                                                        PRIMARY KEY (sku), CONSTRAINT ck_norm_products_price CHECK (unit_price >= 0)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE norm_orders (order_no VARCHAR(20) NOT NULL,
                                               customer_id BIGINT UNSIGNED NOT NULL,
                                                                           ordered_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                                                   PRIMARY KEY (order_no), CONSTRAINT fk_norm_orders_customer
                          FOREIGN KEY (customer_id) REFERENCES norm_customers (id)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE norm_order_items
  (order_no VARCHAR(20) NOT NULL,
                        product_sku VARCHAR(64) NOT NULL,
                                                quantity INT NOT NULL,
                                                             unit_price DECIMAL(12, 2) NOT NULL,
                                                                                       PRIMARY KEY (order_no,
                                                                                                    product_sku), CONSTRAINT fk_norm_items_order
   FOREIGN KEY (order_no) REFERENCES norm_orders (order_no) ON DELETE CASCADE,
                                                                      CONSTRAINT fk_norm_items_product
   FOREIGN KEY (product_sku) REFERENCES norm_products (sku),
                                        CONSTRAINT ck_norm_items_qty CHECK (quantity > 0), CONSTRAINT ck_norm_items_price CHECK (unit_price >= 0)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


INSERT INTO norm_customers (full_name, city, zip_code)
VALUES ('Ann', 'Bangkok', '10110'),
       ('Ben', 'Chiang Mai', '50200');


INSERT INTO norm_products (sku, name, unit_price)
VALUES ('BOOK-001', 'SQL Foundations', 450.00),
       ('BOOK-002', 'PostgreSQL Internals', 890.00),
       ('STICKER-01', 'DB Sticker Pack', 59.00);


INSERT INTO norm_orders (order_no, customer_id)
VALUES ('ORD-1', 1),
       ('ORD-2', 1),
       ('ORD-3', 2);


INSERT INTO norm_order_items (order_no, product_sku, quantity, unit_price)
VALUES ('ORD-1', 'BOOK-001', 1, 450.00),
       ('ORD-1', 'STICKER-01', 2, 59.00),
       ('ORD-2', 'BOOK-002', 1, 890.00),
       ('ORD-3', 'BOOK-001', 2, 450.00);


SELECT o.order_no,
       c.full_name,
       SUM(oi.quantity * oi.unit_price) AS total
FROM norm_orders o
JOIN norm_customers c ON c.id = o.customer_id
JOIN norm_order_items oi ON oi.order_no = o.order_no
GROUP BY o.order_no,
         c.full_name
ORDER BY o.order_no;
