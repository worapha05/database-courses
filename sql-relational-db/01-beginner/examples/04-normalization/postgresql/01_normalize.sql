-- =============================================================================
-- 04-normalization / PostgreSQL
-- แปลงจากตาราง denormalized (0NF) → 1NF → 2NF → 3NF
-- =============================================================================
-- ---------------------------------------------------------------------------
-- ขั้น 0: ตาราง "บาป" — ข้อมูลซ้ำ + repeating group ใน cell
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS messy_orders CASCADE;


CREATE TABLE messy_orders (order_no VARCHAR(20),
                                    customer_name VARCHAR(150),
                                                  customer_city VARCHAR(100),
                                                                customer_zip VARCHAR(20),
                                                                             products TEXT, -- 'SKU-A x2, SKU-B x1' ← ไม่ atomic
 total_amount NUMERIC(12, 2));


INSERT INTO messy_orders
VALUES ('ORD-1', 'Ann', 'Bangkok', '10110', 'BOOK-001 x1, STICKER-01 x2', 568.00),
       ('ORD-2', 'Ann', 'Bangkok', '10110', 'BOOK-002 x1', 890.00),
       ('ORD-3', 'Ben', 'Chiang Mai', '50200', 'BOOK-001 x2', 900.00);

-- ปัญหา: แก้ที่อยู่ Ann ต้องอัปเดตหลายแถว (update anomaly)
--         ลบ order สุดท้ายของ Ben อาจเสียข้อมูลที่อยู่ Ben (delete anomaly)
-- ---------------------------------------------------------------------------
-- 1NF: atomic values → แยกแถวรายการสินค้า
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS orders_1nf CASCADE;


CREATE TABLE orders_1nf (order_no VARCHAR(20) NOT NULL,
                                              customer_name VARCHAR(150) NOT NULL,
                                                                         customer_city VARCHAR(100) NOT NULL,
                                                                                                    customer_zip VARCHAR(20) NOT NULL,
                                                                                                                             product_sku VARCHAR(64) NOT NULL,
                                                                                                                                                     quantity INTEGER NOT NULL,
                                                                                                                                                                      line_amount NUMERIC(12, 2) NOT NULL,
                                                                                                                                                                                                 PRIMARY KEY (order_no,
                                                                                                                                                                                                              product_sku));


INSERT INTO orders_1nf
VALUES ('ORD-1', 'Ann', 'Bangkok', '10110', 'BOOK-001', 1, 450.00),
       ('ORD-1', 'Ann', 'Bangkok', '10110', 'STICKER-01', 2, 118.00),
       ('ORD-2', 'Ann', 'Bangkok', '10110', 'BOOK-002', 1, 890.00),
       ('ORD-3', 'Ben', 'Chiang Mai', '50200', 'BOOK-001', 2, 900.00);

-- ยังผิด 2NF: customer_city พึ่ง customer_name ไม่ใช่ทั้ง composite key
-- ---------------------------------------------------------------------------
-- 2NF + 3NF: แยก customers, products, orders, order_items
-- ---------------------------------------------------------------------------

DROP TABLE IF EXISTS norm_order_items CASCADE;


DROP TABLE IF EXISTS norm_orders CASCADE;


DROP TABLE IF EXISTS norm_products CASCADE;


DROP TABLE IF EXISTS norm_customers CASCADE;


CREATE TABLE norm_customers (id BIGSERIAL PRIMARY KEY,
                                          full_name VARCHAR(150) NOT NULL,
                                                                 city VARCHAR(100) NOT NULL,
                                                                                   zip_code VARCHAR(20) NOT NULL);


CREATE TABLE norm_products (sku VARCHAR(64) PRIMARY KEY,
                                            name VARCHAR(200) NOT NULL,
                                                              unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0));


CREATE TABLE norm_orders (order_no VARCHAR(20) PRIMARY KEY,
                                               customer_id BIGINT NOT NULL REFERENCES norm_customers (id),
                                                                                      ordered_at TIMESTAMPTZ NOT NULL DEFAULT NOW());


CREATE TABLE norm_order_items
  (order_no VARCHAR(20) NOT NULL REFERENCES norm_orders (order_no) ON DELETE CASCADE,
                                                                             product_sku VARCHAR(64) NOT NULL REFERENCES norm_products (sku),
                                                                                                                         quantity INTEGER NOT NULL CHECK (quantity > 0), unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0), PRIMARY KEY (order_no,
                                                                                                                                                                                                                                                  product_sku));


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

-- รายงานเทียบผลรวม

SELECT o.order_no,
       c.full_name,
       SUM(oi.quantity * oi.unit_price) AS total
FROM norm_orders o
JOIN norm_customers c ON c.id = o.customer_id
JOIN norm_order_items oi ON oi.order_no = o.order_no
GROUP BY o.order_no,
         c.full_name
ORDER BY o.order_no;
