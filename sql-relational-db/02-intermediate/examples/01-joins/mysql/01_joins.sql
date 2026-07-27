-- =============================================================================
-- 01-joins / MySQL 8 — INNER / LEFT / RIGHT / SELF + FULL จำลองด้วย UNION
-- =============================================================================
SET NAMES utf8mb4;


SET FOREIGN_KEY_CHECKS = 0;


DROP TABLE IF EXISTS orders;


DROP TABLE IF EXISTS employees;


DROP TABLE IF EXISTS customers;


SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE customers (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                   full_name VARCHAR(120) NOT NULL) ENGINE = InnoDB;


CREATE TABLE employees (id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
                                                    full_name VARCHAR(120) NOT NULL,
                                                                           manager_id BIGINT UNSIGNED NULL,
                                                                                                      department VARCHAR(64) NOT NULL,
                                                                                                                             CONSTRAINT fk_emp_manager
                        FOREIGN KEY (manager_id) REFERENCES employees (id)) ENGINE = InnoDB;


CREATE TABLE orders (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                customer_id BIGINT UNSIGNED NULL,
                                                                                            sales_rep_id BIGINT UNSIGNED NULL,
                                                                                                                         amount DECIMAL(12, 2) NOT NULL,
                                                                                                                                               status VARCHAR(20) NOT NULL,
                                                                                                                                                                  CONSTRAINT fk_ord_customer
                     FOREIGN KEY (customer_id) REFERENCES customers (id),
                                                          CONSTRAINT fk_ord_rep
                     FOREIGN KEY (sales_rep_id) REFERENCES employees (id)) ENGINE = InnoDB;


INSERT INTO customers (full_name)
VALUES ('Ann'),
       ('Ben'),
       ('Cara');


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


SELECT o.id,
       c.full_name AS customer,
       e.full_name AS sales_rep,
       o.amount
FROM orders o
INNER JOIN customers c ON c.id = o.customer_id
INNER JOIN employees e ON e.id = o.sales_rep_id;


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


SELECT o.id,
       c.full_name
FROM customers c
RIGHT JOIN orders o ON o.customer_id = c.id;

-- FULL OUTER JOIN emulation

SELECT e.full_name AS employee,
       o.id AS order_id,
       o.amount
FROM employees e
LEFT JOIN orders o ON o.sales_rep_id = e.id
UNION
SELECT e.full_name,
       o.id,
       o.amount
FROM employees e
RIGHT JOIN orders o ON o.sales_rep_id = e.id
WHERE e.id IS NULL
ORDER BY employee,
         order_id;


SELECT e.full_name AS employee,
       m.full_name AS manager
FROM employees e
LEFT JOIN employees m ON m.id = e.manager_id
ORDER BY e.id;
