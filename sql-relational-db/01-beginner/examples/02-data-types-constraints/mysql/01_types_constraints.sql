-- =============================================================================
-- 02-data-types-constraints / MySQL 8
-- เน้น: type ที่ถูกต้อง + NOT NULL / UNIQUE / CHECK / DEFAULT
-- =============================================================================
SET NAMES utf8mb4;


SET FOREIGN_KEY_CHECKS = 0;


DROP TABLE IF EXISTS inventory_movements;


DROP TABLE IF EXISTS warehouses;


DROP TABLE IF EXISTS sku_catalog;


SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE sku_catalog
  (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                               sku VARCHAR(32) NOT NULL,
                                               title VARCHAR(200) NOT NULL,
                                                                  list_price DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
                                                                                                             weight_kg DECIMAL(8, 3) NULL, -- MySQL ไม่มี array type — เก็บ JSON แทน หรือแยกตาราง tags
 tags_json JSON NOT NULL,
                attrs JSON NOT NULL,
                           is_published TINYINT(1) NOT NULL DEFAULT 0,
                                                                    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                                            updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
                                                                                                                                                                                   PRIMARY KEY (id), CONSTRAINT uq_sku_catalog_sku UNIQUE (sku), CONSTRAINT ck_sku_list_price_nonneg CHECK (list_price >= 0), CONSTRAINT ck_sku_weight_positive CHECK (weight_kg IS NULL
                                                                                                                                                                                                                                                                                                                                                       OR weight_kg > 0)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE warehouses (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                                                     code VARCHAR(16) NOT NULL,
                                                                      name VARCHAR(100) NOT NULL,
                                                                                        PRIMARY KEY (id), CONSTRAINT uq_warehouses_code UNIQUE (code)) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


CREATE TABLE inventory_movements
  (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                               sku_id BIGINT UNSIGNED NOT NULL,
                                                      warehouse_id BIGINT UNSIGNED NOT NULL,
                                                                                   qty_delta INT NOT NULL,
                                                                                                 reason VARCHAR(64) NOT NULL,
                                                                                                                    moved_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                                                                                          PRIMARY KEY (id), CONSTRAINT fk_inv_sku
   FOREIGN KEY (sku_id) REFERENCES sku_catalog (id) ON DELETE RESTRICT,
                                                              CONSTRAINT fk_inv_wh
   FOREIGN KEY (warehouse_id) REFERENCES warehouses (id) ON DELETE RESTRICT,
                                                                   CONSTRAINT ck_inventory_qty_delta_nonzero CHECK (qty_delta <> 0), CONSTRAINT ck_inventory_reason CHECK (reason IN ('receive',
                                                                                                                                                                                      'sale',
                                                                                                                                                                                      'adjust',
                                                                                                                                                                                      'return'))) ENGINE = InnoDB DEFAULT
CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


INSERT INTO warehouses (code, name)
VALUES ('BKK-01', 'Bangkok Main'),
       ('CNX-01', 'Chiang Mai Hub');


INSERT INTO sku_catalog (sku, title, list_price, weight_kg, tags_json, attrs, is_published)
VALUES ('NB-13', 'Notebook 13"', 32900.00, 1.250, JSON_ARRAY('electronics', 'laptop'), JSON_OBJECT('ram_gb', 16, 'storage_gb', 512), 1),
       ('CABLE-USB-C', 'USB-C Cable 1m', 199.00, 0.050, JSON_ARRAY('accessory'), JSON_OBJECT('length_m', 1), 1);


INSERT INTO inventory_movements (sku_id, warehouse_id, qty_delta, reason)
VALUES (1, 1, 10, 'receive'),
       (1, 1, -2, 'sale'),
       (2, 2, 100, 'receive');


SELECT s.sku,
       s.list_price,
       JSON_UNQUOTE(JSON_EXTRACT(s.attrs, '$.ram_gb')) AS ram_gb,
       w.code AS warehouse,
       m.qty_delta,
       m.reason
FROM inventory_movements m
JOIN sku_catalog s ON s.id = m.sku_id
JOIN warehouses w ON w.id = m.warehouse_id
ORDER BY m.id;
