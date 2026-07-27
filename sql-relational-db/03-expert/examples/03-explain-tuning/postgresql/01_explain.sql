-- =============================================================================
-- 03-explain-tuning / PostgreSQL
-- =============================================================================

DROP TABLE IF EXISTS EVENTS CASCADE;


CREATE TABLE EVENTS (id BIGSERIAL PRIMARY KEY,
                                  user_id INT NOT NULL,
                                              event_type VARCHAR(32) NOT NULL,
                                                                     created_at TIMESTAMPTZ NOT NULL);

-- สร้างข้อมูลจำลองจำนวนพอสมควร

INSERT INTO EVENTS (user_id,
                    event_type,
                    created_at)
SELECT (random() * 5000)::int + 1,
       (ARRAY['view',
              'click',
              'purchase']) [1 + (random() * 3)::int],
       NOW() - ((random() * 365)::int || ' days')::interval
FROM generate_series(1, 50000);

ANALYZE EVENTS;

-- ก่อนมี index ที่เหมาะกับ filter
EXPLAIN (ANALYZE,
         BUFFERS)
SELECT *
FROM EVENTS
WHERE user_id = 42
  AND created_at >= NOW() - INTERVAL '30 days'
ORDER BY created_at DESC
LIMIT 50;


CREATE INDEX ix_events_user_created ON EVENTS (user_id,
                                               created_at DESC);

ANALYZE EVENTS;

-- หลังมี composite index
EXPLAIN (ANALYZE,
         BUFFERS)
SELECT *
FROM EVENTS
WHERE user_id = 42
  AND created_at >= NOW() - INTERVAL '30 days'
ORDER BY created_at DESC
LIMIT 50;

-- Partial index สำหรับ purchase ล่าสุด

CREATE INDEX ix_events_purchase_created ON EVENTS (created_at DESC)
WHERE event_type = 'purchase';

EXPLAIN (ANALYZE,
         BUFFERS)
SELECT id,
       user_id,
       created_at
FROM EVENTS
WHERE event_type = 'purchase'
  AND created_at >= NOW() - INTERVAL '7 days'
ORDER BY created_at DESC
LIMIT 20;
