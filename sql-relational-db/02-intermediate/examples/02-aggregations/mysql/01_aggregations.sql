-- =============================================================================
-- 02-aggregations / MySQL 8
-- =============================================================================
SET NAMES utf8mb4;


SET FOREIGN_KEY_CHECKS = 0;


DROP TABLE IF EXISTS order_items;


DROP TABLE IF EXISTS orders;


DROP TABLE IF EXISTS products;


DROP TABLE IF EXISTS customers;


SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE customers (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                   full_name VARCHAR(120) NOT NULL,
                                                                                          city VARCHAR(80) NOT NULL) ENGINE = InnoDB;


CREATE TABLE products (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                  name VARCHAR(120) NOT NULL,
                                                                                    category VARCHAR(64) NOT NULL) ENGINE = InnoDB;


CREATE TABLE orders (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                customer_id BIGINT UNSIGNED NOT NULL,
                                                                                            status VARCHAR(20) NOT NULL,
                                                                                                               ordered_at DATE NOT NULL,
                                                                                                                               CONSTRAINT fk_agg_ord_cust
                     FOREIGN KEY (customer_id) REFERENCES customers (id)) ENGINE = InnoDB;


CREATE TABLE order_items (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                     order_id BIGINT UNSIGNED NOT NULL,
                                                                                              product_id BIGINT UNSIGNED NOT NULL,
                                                                                                                         quantity INT NOT NULL,
                                                                                                                                      unit_price DECIMAL(12, 2) NOT NULL,
                                                                                                                                                                CONSTRAINT fk_agg_oi_ord
                          FOREIGN KEY (order_id) REFERENCES orders (id),
                                                            CONSTRAINT fk_agg_oi_prod
                          FOREIGN KEY (product_id) REFERENCES products (id)) ENGINE = InnoDB;


INSERT INTO customers (full_name, city)
VALUES ('Ann', 'Bangkok'),
       ('Ben', 'Bangkok'),
       ('Cara', 'Chiang Mai');


INSERT INTO products (name, category)
VALUES ('SQL Book', 'Book'),
       ('Sticker', 'Merch'),
       ('Hoodie', 'Merch');


INSERT INTO orders (customer_id, status, ordered_at)
VALUES (1, 'paid', '2026-01-05'),
       (1, 'paid', '2026-02-10'),
       (2, 'paid', '2026-02-11'),
       (2, 'cancelled', '2026-03-01'),
       (3, 'paid', '2026-03-15');


INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (1, 1, 1, 500),
       (1, 2, 3, 50),
       (2, 3, 1, 1200),
       (3, 1, 2, 500),
       (4, 2, 1, 50),
       (5, 1, 1, 500),
       (5, 3, 1, 1200);


SELECT c.full_name,
       COUNT(DISTINCT o.id) AS paid_orders,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.id
AND o.status = 'paid'
JOIN order_items oi ON oi.order_id = o.id
GROUP BY c.id,
         c.full_name
HAVING SUM(oi.quantity * oi.unit_price) >= 1000
ORDER BY revenue DESC;


SELECT p.category,
       SUM(oi.quantity) AS units_sold,
       ROUND(AVG(oi.unit_price), 2) AS avg_unit_price,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN orders o ON o.id = oi.order_id
AND o.status = 'paid'
JOIN products p ON p.id = oi.product_id
GROUP BY p.category
ORDER BY revenue DESC;


SELECT DATE_FORMAT(o.ordered_at, '%Y-%m-01') AS month_start,
       COUNT(*) AS order_count,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
WHERE o.status = 'paid'
GROUP BY DATE_FORMAT(o.ordered_at, '%Y-%m-01')
ORDER BY month_start;


SELECT c.city,
       COUNT(*) AS inflated_rows,
       COUNT(DISTINCT o.id) AS real_orders
FROM customers c
JOIN orders o ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY c.city;
