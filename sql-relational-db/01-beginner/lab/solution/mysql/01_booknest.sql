-- =============================================================================
-- LAB Beginner Solution — BookNest (MySQL 8)
-- =============================================================================
SET NAMES utf8mb4;


SET FOREIGN_KEY_CHECKS = 0;


DROP TABLE IF EXISTS order_items;


DROP TABLE IF EXISTS orders;


DROP TABLE IF EXISTS book_authors;


DROP TABLE IF EXISTS books;


DROP TABLE IF EXISTS categories;


DROP TABLE IF EXISTS authors;


DROP TABLE IF EXISTS customers;


SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE customers (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                                    email VARCHAR(255) NOT NULL,
                                                                       full_name VARCHAR(150) NOT NULL,
                                                                                              created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                                                                      PRIMARY KEY (id), CONSTRAINT uq_customers_email UNIQUE (email)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE authors (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                                  full_name VARCHAR(150) NOT NULL,
                                                                         PRIMARY KEY (id), CONSTRAINT uq_authors_full_name UNIQUE (full_name)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE categories (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                                     name VARCHAR(100) NOT NULL,
                                                                       PRIMARY KEY (id), CONSTRAINT uq_categories_name UNIQUE (name)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE books
  (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                               isbn VARCHAR(20) NOT NULL,
                                                title VARCHAR(200) NOT NULL,
                                                                   category_id BIGINT UNSIGNED NOT NULL,
                                                                                               unit_price DECIMAL(12, 2) NOT NULL,
                                                                                                                         stock_qty INT NOT NULL DEFAULT 0,
                                                                                                                                                        is_active TINYINT(1) NOT NULL DEFAULT 1,
                                                                                                                                                                                              PRIMARY KEY (id), CONSTRAINT uq_books_isbn UNIQUE (isbn), CONSTRAINT fk_books_category
   FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT,
                                                                  CONSTRAINT ck_books_price_nonneg CHECK (unit_price >= 0), CONSTRAINT ck_books_stock_nonneg CHECK (stock_qty >= 0)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE book_authors
  (book_id BIGINT UNSIGNED NOT NULL,
                           author_id BIGINT UNSIGNED NOT NULL,
                                                     author_ord SMALLINT NOT NULL DEFAULT 1,
                                                                                          PRIMARY KEY (book_id,
                                                                                                       author_id), CONSTRAINT fk_ba_book
   FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE,
                                                         CONSTRAINT fk_ba_author
   FOREIGN KEY (author_id) REFERENCES authors (id) ON DELETE RESTRICT,
                                                             CONSTRAINT ck_ba_ord_positive CHECK (author_ord > 0)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE orders
  (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                               customer_id BIGINT UNSIGNED NOT NULL,
                                                           status VARCHAR(32) NOT NULL DEFAULT 'pending',
                                                                                               ordered_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                                                                       PRIMARY KEY (id), CONSTRAINT fk_orders_customer
   FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT,
                                                                 CONSTRAINT ck_orders_status CHECK (status IN ('pending',
                                                                                                               'paid',
                                                                                                               'shipped',
                                                                                                               'cancelled'))) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE order_items
  (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                               order_id BIGINT UNSIGNED NOT NULL,
                                                        book_id BIGINT UNSIGNED NOT NULL,
                                                                                quantity INT NOT NULL,
                                                                                             unit_price DECIMAL(12, 2) NOT NULL,
                                                                                                                       PRIMARY KEY (id), CONSTRAINT fk_oi_order
   FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
                                                           CONSTRAINT fk_oi_book
   FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE RESTRICT,
                                                         CONSTRAINT uq_oi_order_book UNIQUE (order_id,
                                                                                             book_id), CONSTRAINT ck_oi_qty CHECK (quantity > 0), CONSTRAINT ck_oi_price CHECK (unit_price >= 0)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


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


INSERT INTO orders (customer_id, status)
VALUES (3, 'paid');


SET @new_order_id = LAST_INSERT_ID();


INSERT INTO order_items (order_id, book_id, quantity, unit_price)
VALUES (@new_order_id, 1, 1, 550.00),
       (@new_order_id, 4, 2, 750.00);


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
