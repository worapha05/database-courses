-- =============================================================================
-- LAB Expert Solution — StockGuard (PostgreSQL)
-- =============================================================================

DROP TABLE IF EXISTS reservation_audit CASCADE;


DROP TABLE IF EXISTS reservations CASCADE;


DROP TABLE IF EXISTS stock_reservations CASCADE;


DROP TABLE IF EXISTS stock_movements CASCADE;


DROP TABLE IF EXISTS inventory CASCADE;


DROP TABLE IF EXISTS products CASCADE;


CREATE TABLE products (id BIGSERIAL PRIMARY KEY,
                                    sku VARCHAR(32) NOT NULL UNIQUE,
                                                             name VARCHAR(120) NOT NULL);


CREATE TABLE inventory (product_id BIGINT PRIMARY KEY REFERENCES products (id),
                                                                 stock_qty INTEGER NOT NULL CHECK (stock_qty >= 0));


CREATE TABLE reservations (id BIGSERIAL PRIMARY KEY,
                                        product_id BIGINT NOT NULL REFERENCES products (id),
                                                                              qty INTEGER NOT NULL CHECK (qty > 0), status VARCHAR(20) NOT NULL DEFAULT 'reserved' CHECK (status IN ('reserved',
                                                                                                                                                                                     'committed',
                                                                                                                                                                                     'released',
                                                                                                                                                                                     'cancelled')), created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());


CREATE TABLE reservation_audit (id BIGSERIAL PRIMARY KEY,
                                             reservation_id BIGINT NOT NULL,
                                                                   old_status VARCHAR(20),
                                                                              new_status VARCHAR(20),
                                                                                         changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW());


CREATE TABLE stock_movements (id BIGSERIAL PRIMARY KEY,
                                           product_id BIGINT NOT NULL REFERENCES products (id),
                                                                                 moved_at TIMESTAMPTZ NOT NULL,
                                                                                                      qty_delta INTEGER NOT NULL);


INSERT INTO products (sku, name)
VALUES ('WG-1', 'Widget'),
       ('WG-2', 'Gadget'),
       ('WG-3', 'Doohickey');


INSERT INTO inventory (product_id, stock_qty)
VALUES (1, 5),
       (2, 10),
       (3, 2);


INSERT INTO stock_movements (product_id, moved_at, qty_delta)
VALUES (1, '2026-03-01 09:00+00', 10),
       (1, '2026-03-01 12:00+00', -2),
       (1, '2026-03-02 10:00+00', -1),
       (2, '2026-03-01 11:00+00', 20),
       (2, '2026-03-02 09:00+00', -5),
       (3, '2026-03-01 08:00+00', 5),
       (3, '2026-03-01 18:00+00', -3);

-- Audit trigger

CREATE OR REPLACE FUNCTION log_reservation_status () RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO reservation_audit (reservation_id, old_status, new_status)
        VALUES (OLD.id, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_reservation_audit AFTER
UPDATE OF status ON reservations
FOR EACH ROW EXECUTE FUNCTION log_reservation_status ();

-- Atomic reserve

CREATE OR REPLACE FUNCTION reserve_stock (p_product_id BIGINT, p_qty INTEGER) RETURNS BIGINT LANGUAGE PLPGSQL AS $$
DECLARE
    v_stock INTEGER;
    v_id BIGINT;
BEGIN
    IF p_qty IS NULL OR p_qty <= 0 THEN
        RAISE EXCEPTION 'qty must be positive';
    END IF;

    SELECT stock_qty INTO v_stock
    FROM inventory
    WHERE product_id = p_product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'product % not found in inventory', p_product_id;
    END IF;

    IF v_stock < p_qty THEN
        RAISE EXCEPTION 'insufficient stock: have %, need %', v_stock, p_qty;
    END IF;

    UPDATE inventory
    SET stock_qty = stock_qty - p_qty
    WHERE product_id = p_product_id;

    INSERT INTO reservations (product_id, qty, status)
    VALUES (p_product_id, p_qty, 'reserved')
    RETURNING id INTO v_id;

    INSERT INTO stock_movements (product_id, moved_at, qty_delta)
    VALUES (p_product_id, NOW(), -p_qty);

    RETURN v_id;
END;
$$;

-- Demo success

SELECT reserve_stock (1, 2) AS reservation_id;


SELECT stock_qty
FROM inventory
WHERE product_id = 1;

-- Demo failure (uncomment to verify rollback behavior of a single call)
-- SELECT reserve_stock(3, 100);
-- Commit a reservation (triggers audit)

UPDATE reservations
SET status = 'committed'
WHERE id = 1;


SELECT *
FROM reservation_audit;

-- Partial index for open reservations

CREATE INDEX ix_reservations_open_product_created ON reservations (product_id, created_at DESC)
WHERE status = 'reserved';

EXPLAIN (ANALYZE,
         BUFFERS)
SELECT *
FROM reservations
WHERE product_id = 1
  AND status = 'reserved'
ORDER BY created_at DESC;

-- Window: running stock

SELECT product_id,
       moved_at,
       qty_delta,
       SUM(qty_delta) OVER (PARTITION BY product_id
                            ORDER BY moved_at, id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_stock
FROM stock_movements
ORDER BY product_id,
         moved_at,
         id;

-- Window: top movement magnitude per day

SELECT *
FROM
  (SELECT product_id,
          moved_at::date AS DAY,
          qty_delta,
          ABS(qty_delta) AS magnitude,
          ROW_NUMBER() OVER (PARTITION BY moved_at::date
                             ORDER BY ABS(qty_delta) DESC, id) AS rn
   FROM stock_movements) t
WHERE rn = 1
ORDER BY DAY;
