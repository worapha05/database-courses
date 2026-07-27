-- Normalize free-text status into a lookup table id.
-- Assumes user_statuses already seeded with codes: active, disabled, banned

UPDATE users u
SET status_id = s.id
FROM user_statuses s
WHERE u.status_id IS NULL
  AND lower(trim(u.status)) = s.code;

-- Catch unknowns → disabled (or a dedicated 'unknown' code)

UPDATE users u
SET status_id = s.id
FROM user_statuses s
WHERE u.status_id IS NULL
  AND s.code = 'disabled';

-- Verification
-- SELECT status, COUNT(*) FROM users WHERE status_id IS NULL GROUP BY status;
