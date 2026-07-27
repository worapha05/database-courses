-- =============================================================================
-- 03-explain-tuning / MySQL 8
-- =============================================================================
SET NAMES utf8mb4;


DROP TABLE IF EXISTS EVENTS;


CREATE TABLE EVENTS (id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                                                user_id INT NOT NULL,
                                                                            event_type VARCHAR(32) NOT NULL,
                                                                                                   created_at DATETIME(6) NOT NULL) ENGINE = InnoDB;


DROP PROCEDURE IF EXISTS seed_events;


DELIMITER $$
CREATE PROCEDURE seed_events()
BEGIN
  DECLARE i INT DEFAULT 0;
  WHILE i < 20000 DO
    INSERT INTO events (user_id, event_type, created_at)
    VALUES (
      1 + FLOOR(RAND() * 5000),
      ELT(1 + FLOOR(RAND() * 3), 'view', 'click', 'purchase'),
      DATE_SUB(NOW(6), INTERVAL FLOOR(RAND() * 365) DAY)
    );
    SET i = i + 1;
  END WHILE;
END $$
DELIMITER ;

CALL seed_events ();


DROP PROCEDURE seed_events;

ANALYZE TABLE EVENTS;

EXPLAIN ANALYZE
SELECT *
FROM EVENTS
WHERE user_id = 42
  AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
ORDER BY created_at DESC
LIMIT 50;


CREATE INDEX ix_events_user_created ON EVENTS (user_id,
                                               created_at DESC);

ANALYZE TABLE EVENTS;

EXPLAIN ANALYZE
SELECT *
FROM EVENTS
WHERE user_id = 42
  AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
ORDER BY created_at DESC
LIMIT 50;

-- MySQL ไม่มี partial index — ใช้ composite ที่นำด้วย event_type แทน

CREATE INDEX ix_events_type_created ON EVENTS (event_type,
                                               created_at DESC);

EXPLAIN ANALYZE
SELECT id,
       user_id,
       created_at
FROM EVENTS
WHERE event_type = 'purchase'
  AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY created_at DESC
LIMIT 20;
