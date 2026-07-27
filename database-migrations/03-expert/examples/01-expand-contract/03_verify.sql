-- Gate: must be 0 before readers switch exclusively / before NOT NULL

SELECT COUNT(*) AS missing_display_name
FROM accounts
WHERE display_name IS NULL;


SELECT COUNT(*) AS drift
FROM accounts
WHERE full_name IS DISTINCT
  FROM display_name;
