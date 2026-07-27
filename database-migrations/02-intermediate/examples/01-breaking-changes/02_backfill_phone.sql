-- Step 2 (Data): backfill in batches for large tables
-- Run repeatedly until remaining = 0

UPDATE users
SET phone = regexp_replace(mobile, '[^0-9+]', '', 'g')
WHERE phone IS NULL
  AND mobile IS NOT NULL
  AND id IN
    (SELECT id
     FROM users
     WHERE phone IS NULL
       AND mobile IS NOT NULL
     ORDER BY id
     LIMIT 1000);

-- Verification
-- SELECT COUNT(*) FROM users WHERE phone IS NULL AND mobile IS NOT NULL;
