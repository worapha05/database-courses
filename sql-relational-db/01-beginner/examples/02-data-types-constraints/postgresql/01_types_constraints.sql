-- =============================================================================
-- 02-data-types-constraints / PostgreSQL
-- เน้น: type ที่ถูกต้อง + NOT NULL / UNIQUE / CHECK / DEFAULT
-- =============================================================================

DROP TABLE IF EXISTS inventory_movements CASCADE;


DROP TABLE IF EXISTS warehouses CASCADE;


DROP TABLE IF EXISTS sku_catalog CASCADE;


CREATE TABLE sku_catalog (id BIGSERIAL PRIMARY KEY,
                                       sku VARCHAR(32) NOT NULL,
                                                       title VARCHAR(200) NOT NULL, -- เงินห้าม FLOAT
 list_price NUMERIC(12, 2) NOT NULL DEFAULT 0,
                                            weight_kg NUMERIC(8, 3), -- อนุญาต NULL = ยังไม่ชั่ง
 tags TEXT[] NOT NULL DEFAULT '{}', -- PG-specific: array (สอนว่ามี แต่ production มักใช้ตารางแยก)
 attrs JSONB NOT NULL DEFAULT '{}',
                              is_published BOOLEAN NOT NULL DEFAULT FALSE,
                                                                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                                                                                            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                                                                                                                                    CONSTRAINT uq_sku_catalog_sku UNIQUE (sku), CONSTRAINT ck_sku_list_price_nonneg CHECK (list_price >= 0), CONSTRAINT ck_sku_weight_positive CHECK (weight_kg IS NULL
                                                                                                                                                                                                                                                                                                      OR weight_kg > 0));


CREATE TABLE warehouses (id BIGSERIAL PRIMARY KEY,
                                      code VARCHAR(16) NOT NULL,
                                                       name VARCHAR(100) NOT NULL,
                                                                         CONSTRAINT uq_warehouses_code UNIQUE (code));


CREATE TABLE inventory_movements
  (id BIGSERIAL PRIMARY KEY,
                sku_id BIGINT NOT NULL REFERENCES sku_catalog (id) ON DELETE RESTRICT,
                                                                             warehouse_id BIGINT NOT NULL REFERENCES warehouses (id) ON DELETE RESTRICT,
                                                                                                                                               qty_delta INTEGER NOT NULL, -- + รับเข้า / - จ่ายออก
 reason VARCHAR(64) NOT NULL,
                    moved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                                          CONSTRAINT ck_inventory_qty_delta_nonzero CHECK (qty_delta <> 0), CONSTRAINT ck_inventory_reason CHECK (reason IN ('receive',
                                                                                                                                                                             'sale',
                                                                                                                                                                             'adjust',
                                                                                                                                                                             'return')));


INSERT INTO warehouses (code, name)
VALUES ('BKK-01', 'Bangkok Main'),
       ('CNX-01', 'Chiang Mai Hub');


INSERT INTO sku_catalog (sku, title, list_price, weight_kg, tags, attrs, is_published)
VALUES ('NB-13', 'Notebook 13"', 32900.00, 1.250, ARRAY['electronics', 'laptop'], '{"ram_gb": 16, "storage_gb": 512}'::JSONB, TRUE),
       ('CABLE-USB-C', 'USB-C Cable 1m', 199.00, 0.050, ARRAY['accessory'], '{"length_m": 1}'::JSONB, TRUE);


INSERT INTO inventory_movements (sku_id, warehouse_id, qty_delta, reason)
VALUES (1, 1, 10, 'receive'),
       (1, 1, -2, 'sale'),
       (2, 2, 100, 'receive');

-- ทดลอง constraint (ควรถูก reject) — uncomment เพื่อทดสอบ
-- INSERT INTO sku_catalog (sku, title, list_price) VALUES ('X', 'Bad', -1);
-- INSERT INTO inventory_movements (sku_id, warehouse_id, qty_delta, reason)
-- VALUES (1, 1, 0, 'sale');

SELECT s.sku,
       s.list_price,
       s.attrs ->> 'ram_gb' AS ram_gb,
       w.code AS warehouse,
       m.qty_delta,
       m.reason
FROM inventory_movements m
JOIN sku_catalog s ON s.id = m.sku_id
JOIN warehouses w ON w.id = m.warehouse_id
ORDER BY m.id;
