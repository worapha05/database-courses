-- =============================================================================
-- LAB Beginner Solution — BookNest (PostgreSQL)
-- =============================================================================

DROP TABLE IF EXISTS order_items CASCADE;


DROP TABLE IF EXISTS orders CASCADE;


DROP TABLE IF EXISTS book_authors CASCADE;


DROP TABLE IF EXISTS books CASCADE;


DROP TABLE IF EXISTS categories CASCADE;


DROP TABLE IF EXISTS authors CASCADE;


DROP TABLE IF EXISTS customers CASCADE;


CREATE TABLE customers (id BIGSERIAL PRIMARY KEY,
                                     email VARCHAR(255) NOT NULL,
                                                        full_name VARCHAR(150) NOT NULL,
                                                                               created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                                                                                                       CONSTRAINT uq_customers_email UNIQUE (email));


CREATE TABLE authors (id BIGSERIAL PRIMARY KEY,
                                   full_name VARCHAR(150) NOT NULL,
                                                          CONSTRAINT uq_authors_full_name UNIQUE (full_name));


CREATE TABLE categories (id BIGSERIAL PRIMARY KEY,
                                      name VARCHAR(100) NOT NULL,
                                                        CONSTRAINT uq_categories_name UNIQUE (name));


CREATE TABLE books
  (id BIGSERIAL PRIMARY KEY,
                isbn VARCHAR(20) NOT NULL,
                                 title VARCHAR(200) NOT NULL,
                                                    category_id BIGINT NOT NULL,
                                                                       unit_price NUMERIC(12, 2) NOT NULL,
                                                                                                 stock_qty INTEGER NOT NULL DEFAULT 0,
                                                                                                                                    is_active BOOLEAN NOT NULL DEFAULT TRUE,
                                                                                                                                                                       CONSTRAINT uq_books_isbn UNIQUE (isbn), CONSTRAINT fk_books_category
   FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT,
                                                                  CONSTRAINT ck_books_price_nonneg CHECK (unit_price >= 0), CONSTRAINT ck_books_stock_nonneg CHECK (stock_qty >= 0));


CREATE TABLE book_authors
  (book_id BIGINT NOT NULL,
                  author_id BIGINT NOT NULL,
                                   author_ord SMALLINT NOT NULL DEFAULT 1,
                                                                        PRIMARY KEY (book_id,
                                                                                     author_id), CONSTRAINT fk_ba_book
   FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE,
                                                         CONSTRAINT fk_ba_author
   FOREIGN KEY (author_id) REFERENCES authors (id) ON DELETE RESTRICT,
                                                             CONSTRAINT ck_ba_ord_positive CHECK (author_ord > 0));


CREATE TABLE orders
  (id BIGSERIAL PRIMARY KEY,
                customer_id BIGINT NOT NULL,
                                   status VARCHAR(32) NOT NULL DEFAULT 'pending',
                                                                       ordered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                                                                                               CONSTRAINT fk_orders_customer
   FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT,
                                                                 CONSTRAINT ck_orders_status CHECK (status IN ('pending',
                                                                                                               'paid',
                                                                                                               'shipped',
                                                                                                               'cancelled')));


CREATE TABLE order_items
  (id BIGSERIAL PRIMARY KEY,
                order_id BIGINT NOT NULL,
                                book_id BIGINT NOT NULL,
                                               quantity INTEGER NOT NULL,
                                                                unit_price NUMERIC(12, 2) NOT NULL,
                                                                                          CONSTRAINT fk_oi_order
   FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
                                                           CONSTRAINT fk_oi_book
   FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE RESTRICT,
                                                         CONSTRAINT uq_oi_order_book UNIQUE (order_id,
                                                                                             book_id), CONSTRAINT ck_oi_qty CHECK (quantity > 0), CONSTRAINT ck_oi_price CHECK (unit_price >= 0));

-- Seed

INSERT INTO customers (email, full_name)
VALUES ('mira@ex.com', 'Mira Chan'),
       ('noon@ex.com', 'Noon P.'),
       ('oak@ex.com', 'Oak S.');


INSERT INTO authors (full_name)
VALUES ('Alice Nguyen'),
       ('Bob Smith'),
       ('Robert C. Martin'),
       ('Elena Cruz');


INSERT INTO categories (name)
VALUES ('Database'),
       ('Software'),
       ('Career');


INSERT INTO books (isbn, title, category_id, unit_price, stock_qty)
VALUES ('978-1', 'Learning SQL', 1, 550.00, 30),
       ('978-2', 'Clean Code', 2, 690.00, 12),
       ('978-3', 'PostgreSQL Guide', 1, 820.00, 8),
       ('978-4', 'Refactoring', 2, 750.00, 15),
       ('978-5', 'Career for Devs', 3, 390.00, 5);


INSERT INTO book_authors (book_id, author_id, author_ord)
VALUES (1, 1, 1),
       (1, 2, 2),
       (2, 3, 1),
       (3, 1, 1),
       (4, 3, 1),
       (5, 4, 1);


INSERT INTO orders (customer_id, status)
VALUES (1, 'paid'),
       (2, 'paid'),
       (1, 'pending');


INSERT INTO order_items (order_id, book_id, quantity, unit_price)
VALUES (1, 1, 2, 550.00),
       (1, 2, 1, 690.00),
       (2, 3, 1, 820.00),
       (3, 5, 1, 390.00);

-- ส่วนที่ 3: ออเดอร์ใหม่ + ลดสต็อก
WITH new_order AS
  (INSERT INTO orders (customer_id, status)
   VALUES (3,
           'paid') RETURNING id)
INSERT INTO order_items (order_id, book_id, quantity, unit_price)
SELECT id,
       1,
       1,
       550.00
FROM new_order
UNION ALL
SELECT id,
       4,
       2,
       750.00
FROM new_order;


UPDATE books
SET stock_qty = stock_qty - 1
WHERE id = 1;


UPDATE books
SET stock_qty = stock_qty - 2
WHERE id = 4;


UPDATE orders
SET status = 'cancelled'
WHERE id = 3;


SELECT b.title,
       c.name AS category,
       b.stock_qty
FROM books b
JOIN categories c ON c.id = b.category_id
WHERE b.stock_qty < 10
ORDER BY b.stock_qty;

-- Integrity demos (ต้อง error — uncomment ทีละบรรทัด)
-- INSERT INTO books (isbn, title, category_id, unit_price, stock_qty)
-- VALUES ('978-x', 'Bad', 1, -10, 1);
-- INSERT INTO order_items (order_id, book_id, quantity, unit_price)
-- VALUES (1, 9999, 1, 100);
-- INSERT INTO book_authors (book_id, author_id) VALUES (1, 1);
