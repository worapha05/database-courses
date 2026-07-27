-- =============================================================================
-- 01-joins / PostgreSQL — ชุดข้อมูลพนักงาน + ออเดอร์
-- =============================================================================

DROP TABLE IF EXISTS orders CASCADE;


DROP TABLE IF EXISTS employees CASCADE;


DROP TABLE IF EXISTS customers CASCADE;


CREATE TABLE customers (id BIGSERIAL PRIMARY KEY,
                                     full_name VARCHAR(120) NOT NULL);


CREATE TABLE employees (id BIGSERIAL PRIMARY KEY,
                                     full_name VARCHAR(120) NOT NULL,
                                                            manager_id BIGINT REFERENCES employees (id),
                                                                                         department VARCHAR(64) NOT NULL);


CREATE TABLE orders (id BIGSERIAL PRIMARY KEY,
                                  customer_id BIGINT REFERENCES customers (id),
                                                                sales_rep_id BIGINT REFERENCES employees (id),
                                                                                               amount NUMERIC(12, 2) NOT NULL,
                                                                                                                     status VARCHAR(20) NOT NULL);


INSERT INTO customers (full_name)
VALUES ('Ann'),
       ('Ben'),
       ('Cara');

-- Cara ยังไม่มีออเดอร์

INSERT INTO employees (id, full_name, manager_id, department)
VALUES (1, 'Director Dana', NULL, 'Sales'),
       (2, 'Mgr Mina', 1, 'Sales'),
       (3, 'Rep Rin', 2, 'Sales'),
       (4, 'Rep Rob', 2, 'Sales'),
       (5, 'Ops Olive', 1, 'Ops');


INSERT INTO orders (customer_id, sales_rep_id, amount, status)
VALUES (1, 3, 500, 'paid'),
       (1, 3, 200, 'paid'),
       (2, 4, 900, 'pending'),
       (2, NULL, 100, 'paid');

-- ออเดอร์ไม่มี sales rep
-- INNER: เฉพาะออเดอร์ที่มีลูกค้าและมีพนักงานขาย

SELECT o.id,
       c.full_name AS customer,
       e.full_name AS sales_rep,
       o.amount
FROM orders o
INNER JOIN customers c ON c.id = o.customer_id
INNER JOIN employees e ON e.id = o.sales_rep_id;

-- LEFT: ลูกค้าทุกคน + ออเดอร์ถ้ามี (หาลูกค้าที่ยังไม่ซื้อ)

SELECT c.full_name,
       o.id AS order_id,
       o.amount
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
ORDER BY c.id,
         o.id;


SELECT c.full_name AS customers_without_orders
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;

-- RIGHT: ออเดอร์ทั้งหมด + ลูกค้า (เทียบเท่า LEFT ที่สลับตาราง)

SELECT o.id,
       c.full_name
FROM customers c
RIGHT JOIN orders o ON o.customer_id = c.id;

-- FULL OUTER: พนักงานขายทุกคน vs ออเดอร์ที่มี sales_rep

SELECT e.full_name AS employee,
       o.id AS order_id,
       o.amount
FROM employees e
FULL OUTER JOIN orders o ON o.sales_rep_id = e.id
ORDER BY e.id NULLS LAST,
         o.id;

-- SELF JOIN: พนักงานกับหัวหน้า

SELECT e.full_name AS employee,
       m.full_name AS manager
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id
ORDER BY e.id;
