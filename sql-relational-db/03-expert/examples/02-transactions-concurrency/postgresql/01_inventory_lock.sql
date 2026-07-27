-- =============================================================================
-- 02-transactions-concurrency / PostgreSQL
-- สาธิตจองสต็อกแบบปลอดภัยด้วย BEGIN + SELECT FOR UPDATE
-- เปิดสอง session เพื่อทดลอง race (คำแนะนำใน README)
-- =============================================================================

DROP TABLE IF EXISTS stock_reservations CASCADE;


DROP TABLE IF EXISTS inventory CASCADE;


DROP TABLE IF EXISTS products CASCADE;


CREATE TABLE products (id BIGSERIAL PRIMARY KEY,
                                    sku VARCHAR(32) NOT NULL UNIQUE,
                                                             name VARCHAR(120) NOT NULL);


CREATE TABLE inventory (product_id BIGINT PRIMARY KEY REFERENCES products (id),
                                                                 stock_qty INTEGER NOT NULL CHECK (stock_qty >= 0));


CREATE TABLE stock_reservations (id BIGSERIAL PRIMARY KEY,
                                              product_id BIGINT NOT NULL REFERENCES products (id),
                                                                                    qty INTEGER NOT NULL CHECK (qty > 0), status VARCHAR(20) NOT NULL DEFAULT 'reserved' CHECK (status IN ('reserved',
                                                                                                                                                                                           'committed',
                                                                                                                                                                                           'released')), created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());


INSERT INTO products (sku, name)
VALUES ('SKU-1', 'Limited Widget');


INSERT INTO inventory (product_id, stock_qty)
VALUES (1, 5);

-- ---- รูปแบบจองสต็อกที่ถูกต้อง (รันใน transaction เดียว) ----
BEGIN;


SELECT stock_qty
FROM inventory
WHERE product_id = 1
  FOR
  UPDATE;

-- ล็อกแถว กัน session อื่นจองพร้อมกัน
-- สมมติต้องการจอง 2 ชิ้น; ตรวจในแอป/SQL ว่า stock พอ

UPDATE inventory
SET stock_qty = stock_qty - 2
WHERE product_id = 1
  AND stock_qty >= 2;


INSERT INTO stock_reservations (product_id, qty, status)
VALUES (1, 2, 'reserved');


COMMIT;


SELECT *
FROM inventory;


SELECT *
FROM stock_reservations;

-- ---- แสดง isolation (อ่านประกอบเอกสาร) ----
-- Session A: BEGIN; SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- Session B: อัปเดตแถวแล้ว COMMIT;
-- Session A: SELECT ซ้ำ — ใน RR ของ PG จะยังเห็น snapshot เดิม
SHOW default_transaction_isolation;
