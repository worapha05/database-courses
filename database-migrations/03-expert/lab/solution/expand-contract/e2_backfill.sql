INSERT INTO account_billing_profiles (account_id, address, city, country, updated_at)
SELECT id,
       billing_address,
       billing_city,
       billing_country,
       NOW()
FROM accounts a
WHERE NOT EXISTS
    (SELECT 1
     FROM account_billing_profiles p
     WHERE p.account_id = a.id);
