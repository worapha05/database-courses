-- =============================================================================
-- 05-functions-triggers / MySQL 8 Stored Programs
-- =============================================================================
SET NAMES utf8mb4;


SET FOREIGN_KEY_CHECKS = 0;


DROP TRIGGER IF EXISTS trg_orders_audit_status;


DROP PROCEDURE IF EXISTS create_order;


DROP TABLE IF EXISTS order_audit;


DROP TABLE IF EXISTS orders;


SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE orders
  (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                              customer_id BIGINT UNSIGNED NOT NULL,
                                                                          status VARCHAR(20) NOT NULL DEFAULT 'pending',
                                                                                                              total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
                                                                                                                                                           created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                                                                                                                                                                                   updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
                                                                                                                                                                                                                                                                          CONSTRAINT ck_fn_orders_total CHECK (total_amount >= 0)) ENGINE = InnoDB;


CREATE TABLE order_audit (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                     order_id BIGINT UNSIGNED NOT NULL,
                                                                                              old_status VARCHAR(20) NULL,
                                                                                                                     new_status VARCHAR(20) NULL,
                                                                                                                                            changed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)) ENGINE = InnoDB;


DROP TRIGGER IF EXISTS trg_orders_audit_status;


DELIMITER $$
CREATE TRIGGER trg_orders_audit_status
AFTER UPDATE ON orders FOR EACH ROW
BEGIN
  IF NEW.status <> OLD.status THEN
    INSERT INTO order_audit (order_id, old_status, new_status)
    VALUES (OLD.id, OLD.status, NEW.status);
  END IF;
END $$
DROP PROCEDURE IF EXISTS create_order$$
CREATE PROCEDURE create_order(IN p_customer_id BIGINT UNSIGNED, IN p_total DECIMAL(12, 2), OUT p_new_id BIGINT UNSIGNED) BEGIN
INSERT INTO orders (customer_id, total_amount)
VALUES (p_customer_id,
        p_total);
SET p_new_id = LAST_INSERT_ID(); END $$
DELIMITER ;

CALL create_order (101, 1500.00, @oid);


SELECT @oid AS new_order_id;


UPDATE orders
SET status = 'paid'
WHERE id = @oid;


SELECT *
FROM orders;


SELECT *
FROM order_audit;
