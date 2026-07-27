-- =============================================================================
-- LAB Expert Solution — StockGuard (MySQL 8)
-- =============================================================================
SET NAMES utf8mb4;


SET FOREIGN_KEY_CHECKS = 0;


DROP TABLE IF EXISTS reservation_audit;


DROP TABLE IF EXISTS reservations;


DROP TABLE IF EXISTS stock_reservations;


DROP TABLE IF EXISTS stock_movements;


DROP TABLE IF EXISTS inventory;


DROP TABLE IF EXISTS products;


SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE products (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                  sku VARCHAR(32) NOT NULL,
                                                                                  name VARCHAR(120) NOT NULL,
                                                                                                    UNIQUE KEY uq_sg_products_sku (sku)) ENGINE = InnoDB;


CREATE TABLE inventory (product_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
                                                            stock_qty INT NOT NULL,
                                                                          CONSTRAINT fk_sg_inv_product
                        FOREIGN KEY (product_id) REFERENCES products (id),
                                                            CONSTRAINT ck_sg_inv_stock CHECK (stock_qty >= 0)) ENGINE = InnoDB;


CREATE TABLE reservations (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                      product_id BIGINT UNSIGNED NOT NULL,
                                                                                                 qty INT NOT NULL,
                                                                                                         status VARCHAR(20) NOT NULL DEFAULT 'reserved',
                                                                                                                                             created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                                                                                                                     CONSTRAINT fk_sg_res_product
                           FOREIGN KEY (product_id) REFERENCES products (id),
                                                               CONSTRAINT ck_sg_res_qty CHECK (qty > 0), CONSTRAINT ck_sg_res_status CHECK (status IN ('reserved',
                                                                                                                                                       'committed',
                                                                                                                                                       'released',
                                                                                                                                                       'cancelled'))) ENGINE = InnoDB;


CREATE TABLE reservation_audit (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                           reservation_id BIGINT UNSIGNED NOT NULL,
                                                                                                          old_status VARCHAR(20) NULL,
                                                                                                                                 new_status VARCHAR(20) NULL,
                                                                                                                                                        changed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)) ENGINE = InnoDB;


CREATE TABLE stock_movements (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                         product_id BIGINT UNSIGNED NOT NULL,
                                                                                                    moved_at DATETIME(6) NOT NULL,
                                                                                                                         qty_delta INT NOT NULL,
                                                                                                                                       CONSTRAINT fk_sg_mv_product
                              FOREIGN KEY (product_id) REFERENCES products (id)) ENGINE = InnoDB;


INSERT INTO products (sku, name)
VALUES ('WG-1', 'Widget'),
       ('WG-2', 'Gadget'),
       ('WG-3', 'Doohickey');


INSERT INTO inventory (product_id, stock_qty)
VALUES (1, 5),
       (2, 10),
       (3, 2);


INSERT INTO stock_movements (product_id, moved_at, qty_delta)
VALUES (1, '2026-03-01 09:00:00', 10),
       (1, '2026-03-01 12:00:00', -2),
       (1, '2026-03-02 10:00:00', -1),
       (2, '2026-03-01 11:00:00', 20),
       (2, '2026-03-02 09:00:00', -5),
       (3, '2026-03-01 08:00:00', 5),
       (3, '2026-03-01 18:00:00', -3);


DROP TRIGGER IF EXISTS trg_reservation_audit;


DELIMITER $$
CREATE TRIGGER trg_reservation_audit
AFTER UPDATE ON reservations FOR EACH ROW
BEGIN
  IF NEW.status <> OLD.status THEN
    INSERT INTO reservation_audit (reservation_id, old_status, new_status)
    VALUES (OLD.id, OLD.status, NEW.status);
  END IF;
END $$
DROP PROCEDURE IF EXISTS reserve_stock$$
CREATE PROCEDURE reserve_stock(IN p_product_id BIGINT UNSIGNED, IN p_qty INT, OUT p_reservation_id BIGINT UNSIGNED) BEGIN DECLARE v_stock INT; DECLARE EXIT
HANDLER FOR
SQLEXCEPTION BEGIN
ROLLBACK; RESIGNAL; END; IF p_qty IS NULL
OR p_qty <= 0 THEN SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'qty must be positive'; END IF;
START TRANSACTION;
SELECT stock_qty INTO v_stock
FROM inventory
WHERE product_id = p_product_id
  FOR
  UPDATE; IF v_stock IS NULL THEN SIGNAL SQLSTATE '45000'
  SET MESSAGE_TEXT = 'product not found in inventory'; END IF; IF v_stock < p_qty THEN SIGNAL SQLSTATE '45000'
  SET MESSAGE_TEXT = 'insufficient stock'; END IF;
  UPDATE inventory
  SET stock_qty = stock_qty - p_qty WHERE product_id = p_product_id;
  INSERT INTO reservations (product_id, qty, status)
VALUES (p_product_id,
        p_qty,
        'reserved');
SET p_reservation_id = LAST_INSERT_ID();
INSERT INTO stock_movements (product_id, moved_at, qty_delta)
VALUES (p_product_id,
        UTC_TIMESTAMP(6), -p_qty);
COMMIT; END $$
DELIMITER ; CALL reserve_stock (1, 2, @rid);
SELECT @rid AS reservation_id;
SELECT stock_qty
FROM inventory
WHERE product_id = 1;
  UPDATE reservations
  SET status = 'committed' WHERE id = @rid;
  SELECT *
  FROM reservation_audit;
  CREATE INDEX ix_reservations_status_product_created ON reservations (status, product_id, created_at DESC); EXPLAIN ANALYZE
  SELECT *
  FROM reservations WHERE product_id = 1
  AND status = 'reserved'
ORDER BY created_at DESC;
SELECT product_id,
       moved_at,
       qty_delta,
       SUM(qty_delta) OVER (PARTITION BY product_id
                            ORDER BY moved_at, id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_stock
FROM stock_movements
ORDER BY product_id,
         moved_at,
         id;
SELECT *
FROM
  (SELECT product_id,
          DATE(moved_at) AS DAY,
          qty_delta,
          ABS(qty_delta) AS magnitude,
          ROW_NUMBER() OVER (PARTITION BY DATE(moved_at)
                             ORDER BY ABS(qty_delta) DESC, id) AS rn
   FROM stock_movements) t
WHERE rn = 1
ORDER BY DAY;
