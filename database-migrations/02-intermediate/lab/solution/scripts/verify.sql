-- Must all return 0 after successful refactor (before/after drop as noted)

SELECT COUNT(*) AS missing_names
FROM users
WHERE first_name IS NULL
  OR last_name IS NULL;


SELECT COUNT(*) AS unmapped_status
FROM users
WHERE status_id IS NULL;


SELECT COUNT(*) AS orphan_status_fk
FROM users u
LEFT JOIN user_statuses s ON s.id = u.status_id
WHERE s.id IS NULL;

-- After contract step, legacy columns should be gone:
-- SELECT column_name FROM information_schema.columns
-- WHERE table_name = 'users' AND column_name IN ('full_name', 'status');
