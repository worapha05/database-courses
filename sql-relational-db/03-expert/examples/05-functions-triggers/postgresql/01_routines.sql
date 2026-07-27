-- =============================================================================
-- 05-functions-triggers / PostgreSQL (PL/pgSQL)
-- =============================================================================

DROP TABLE IF EXISTS order_audit CASCADE;


DROP TABLE IF EXISTS orders CASCADE;


CREATE TABLE orders (id BIGSERIAL PRIMARY KEY,
                                  customer_id BIGINT NOT NULL,
                                                     status VARCHAR(20) NOT NULL DEFAULT 'pending',
                                                                                         total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0), created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                                                                                                                                                                                           updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW());


CREATE TABLE order_audit (id BIGSERIAL PRIMARY KEY,
                                       order_id BIGINT NOT NULL,
                                                       old_status VARCHAR(20),
                                                                  new_status VARCHAR(20),
                                                                             changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW());

-- อัปเดต updated_at อัตโนมัติ

CREATE OR REPLACE FUNCTION set_updated_at () RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_orders_set_updated_at
BEFORE
UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION set_updated_at ();

-- บันทึกเมื่อสถานะเปลี่ยน

CREATE OR REPLACE FUNCTION log_order_status_change () RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO order_audit (order_id, old_status, new_status)
        VALUES (OLD.id, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_orders_audit_status AFTER
UPDATE OF status ON orders
FOR EACH ROW EXECUTE FUNCTION log_order_status_change ();

-- Stored function: สร้างออเดอร์แล้วคืน id

CREATE OR REPLACE FUNCTION create_order (p_customer_id BIGINT, p_total NUMERIC) RETURNS BIGINT LANGUAGE PLPGSQL AS $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO orders (customer_id, total_amount)
    VALUES (p_customer_id, p_total)
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$;


SELECT create_order (101, 1500.00) AS new_order_id;


UPDATE orders
SET status = 'paid'
WHERE id = 1;


SELECT *
FROM orders;


SELECT *
FROM order_audit;
