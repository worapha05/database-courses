-- Legacy users sample data for Intermediate lab

CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY,
                                            full_name TEXT NOT NULL,
                                                           email TEXT NOT NULL UNIQUE,
                                                                               phone TEXT, status TEXT NOT NULL,
                                                                                                       created_at TIMESTAMPTZ NOT NULL DEFAULT now());


INSERT INTO users (full_name, email, phone, status)
SELECT names.n,
       'user' || g || '@example.com',
       CASE
           WHEN g % 3 = 0 THEN NULL
           ELSE '08' || lpad((10000000 + g)::text, 8, '0')
       END, (ARRAY['active',
                   'Active',
                   'disabled',
                   'banned',
                   'ACTIVE',
                   'unknown'])[1 + (g % 6)]
FROM generate_series(1, 120) AS g
CROSS JOIN LATERAL
  (SELECT (ARRAY[ 'Ada Lovelace',
                  'Grace',
                  'Alan Mathison Turing',
                  'Edsger W. Dijkstra',
                  '  Linus Torvalds ',
                  'Katherine Johnson' ])[1 + (g % 6)] AS n) NAMES ON CONFLICT (email) DO NOTHING;
