-- Run only after v1 drained and verify.sql passes

ALTER TABLE accounts
DROP COLUMN IF EXISTS billing_address,
DROP COLUMN IF EXISTS billing_city,
DROP COLUMN IF EXISTS billing_country;
