DO $$
DECLARE missing bigint;
BEGIN
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
    RAISE EXCEPTION 'Backfill incomplete: % rows', missing;
  END IF;
END $$;
