-- =============================================================================
-- 02-aggregations / PostgreSQL
-- =============================================================================

DROP TABLE IF EXISTS order_items CASCADE;


DROP TABLE IF EXISTS orders CASCADE;


DROP TABLE IF EXISTS products CASCADE;


DROP TABLE IF EXISTS customers CASCADE;


CREATE TABLE customers (id BIGSERIAL PRIMARY KEY,
                                     full_name VARCHAR(120) NOT NULL,
                                                            city VARCHAR(80) NOT NULL);


CREATE TABLE products (id BIGSERIAL PRIMARY KEY,
                                    name VARCHAR(120) NOT NULL,
                                                      category VARCHAR(64) NOT NULL);


CREATE TABLE orders (id BIGSERIAL PRIMARY KEY,
                                  customer_id BIGINT NOT NULL REFERENCES customers (id),
                                                                         status VARCHAR(20) NOT NULL,
                                                                                            ordered_at DATE NOT NULL);


CREATE TABLE order_items (id BIGSERIAL PRIMARY KEY,
                                       order_id BIGINT NOT NULL REFERENCES orders (id),
                                                                           product_id BIGINT NOT NULL REFERENCES products (id),
                                                                                                                 quantity INT NOT NULL,
                                                                                                                              unit_price NUMERIC(12, 2) NOT NULL);


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

-- ยอดขายต่อลูกค้า (เฉพาะ paid) + HAVING

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

-- ยอดขายรายหมวด

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

-- ยอดขายรายเดือน

SELECT date_trunc('month', o.ordered_at)::date AS month_start,
       COUNT(*) AS order_count,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
WHERE o.status = 'paid'
GROUP BY 1
ORDER BY 1;

-- ระวัง fan-out: นับออเดอร์หลัง join items ต้องใช้ COUNT(DISTINCT)

SELECT c.city,
       COUNT(*) AS inflated_rows,
       COUNT(DISTINCT o.id) AS real_orders
FROM customers c
JOIN orders o ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY c.city;
