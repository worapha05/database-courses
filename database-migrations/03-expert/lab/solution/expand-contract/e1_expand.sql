CREATE TABLE IF NOT EXISTS account_billing_profiles
  (account_id BIGINT PRIMARY KEY REFERENCES accounts (id) ON DELETE CASCADE,
                                                                    address TEXT, city TEXT, country CHAR(2),
                                                                                                     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
