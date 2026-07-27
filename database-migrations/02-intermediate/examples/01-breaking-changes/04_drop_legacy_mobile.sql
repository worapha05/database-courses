-- Step 4 (Contract): only after all app versions stopped reading/writing mobile

ALTER TABLE users
DROP COLUMN IF EXISTS mobile;
