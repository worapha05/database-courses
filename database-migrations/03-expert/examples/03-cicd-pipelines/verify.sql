-- Post-migration verification gates (exit non-zero via psql ON_ERROR_STOP + wrappers)
 DO $$
DECLARE
  missing bigint;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'account_billing_profiles'
  ) THEN
    RAISE EXCEPTION 'Gate failed: account_billing_profiles missing';
  END IF;

  SELECT COUNT(*) INTO missing
  FROM accounts a
  LEFT JOIN account_billing_profiles p ON p.account_id = a.id
  WHERE p.account_id IS NULL
    AND (
      a.billing_address IS NOT NULL
      OR a.billing_city IS NOT NULL
      OR a.billing_country IS NOT NULL
    );

  IF missing > 0 THEN
    RAISE EXCEPTION 'Gate failed: % accounts missing billing profile backfill', missing;
  END IF;
END $$;


SELECT 'verification_ok' AS status;
