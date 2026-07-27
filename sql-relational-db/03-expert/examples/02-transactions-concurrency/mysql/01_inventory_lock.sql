-- =============================================================================
-- 02-transactions-concurrency / MySQL 8
-- =============================================================================
SET NAMES utf8mb4;


SET FOREIGN_KEY_CHECKS = 0;


DROP TABLE IF EXISTS stock_reservations;


DROP TABLE IF EXISTS inventory;


DROP TABLE IF EXISTS products;


SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE products (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                  sku VARCHAR(32) NOT NULL,
                                                                                  name VARCHAR(120) NOT NULL,
                                                                                                    UNIQUE KEY uq_products_sku (sku)) ENGINE = InnoDB;


CREATE TABLE inventory (product_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
                                                            stock_qty INT NOT NULL,
                                                                          CONSTRAINT fk_tx_inv_product
                        FOREIGN KEY (product_id) REFERENCES products (id),
                                                            CONSTRAINT ck_tx_inv_stock CHECK (stock_qty >= 0)) ENGINE = InnoDB;


CREATE TABLE stock_reservations (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                            product_id BIGINT UNSIGNED NOT NULL,
                                                                                                       qty INT NOT NULL,
                                                                                                               status VARCHAR(20) NOT NULL DEFAULT 'reserved',
                                                                                                                                                   created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                                                                                                                           CONSTRAINT fk_tx_res_product
                                 FOREIGN KEY (product_id) REFERENCES products (id),
                                                                     CONSTRAINT ck_tx_res_qty CHECK (qty > 0), CONSTRAINT ck_tx_res_status CHECK (status IN ('reserved',
                                                                                                                                                             'committed',
                                                                                                                                                             'released'))) ENGINE = InnoDB;


INSERT INTO products (sku, name)
VALUES ('SKU-1', 'Limited Widget');


INSERT INTO inventory (product_id, stock_qty)
VALUES (1, 5);


START TRANSACTION;


SELECT stock_qty
FROM inventory
WHERE product_id = 1
  FOR
  UPDATE;


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


SELECT @@transaction_isolation;
