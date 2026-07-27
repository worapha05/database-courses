-- =============================================================================
-- 01-window-functions / PostgreSQL
-- =============================================================================

DROP TABLE IF EXISTS sales CASCADE;


CREATE TABLE sales (id BIGSERIAL PRIMARY KEY,
                                 region VARCHAR(32) NOT NULL,
                                                    seller VARCHAR(64) NOT NULL,
                                                                       sold_on DATE NOT NULL,
                                                                                    amount NUMERIC(12, 2) NOT NULL);


INSERT INTO sales (region, seller, sold_on, amount)
VALUES ('BKK', 'Ann', '2026-01-05', 1000),
       ('BKK', 'Ann', '2026-02-05', 1200),
       ('BKK', 'Ben', '2026-01-08', 900),
       ('BKK', 'Ben', '2026-02-08', 1500),
       ('CNX', 'Cara', '2026-01-10', 700),
       ('CNX', 'Cara', '2026-02-10', 800),
       ('CNX', 'Dee', '2026-01-12', 1100),
       ('CNX', 'Dee', '2026-02-12', 1100);

-- อันดับยอดขายต่อภูมิภาค

SELECT region,
       seller,
       amount,
       ROW_NUMBER() OVER (PARTITION BY region
                          ORDER BY amount DESC) AS rn,
       RANK() OVER (PARTITION BY region
                    ORDER BY amount DESC) AS rnk,
       DENSE_RANK() OVER (PARTITION BY region
                          ORDER BY amount DESC) AS dense_rnk
FROM sales
WHERE sold_on >= '2026-02-01'
ORDER BY region,
         rn;

-- MoM เปรียบเทียบด้วย LAG

SELECT seller,
       sold_on,
       amount,
       LAG(amount) OVER (PARTITION BY seller
                         ORDER BY sold_on) AS prev_amount,
       amount - LAG(amount) OVER (PARTITION BY seller
                                  ORDER BY sold_on) AS delta,
       LEAD(amount) OVER (PARTITION BY seller
                          ORDER BY sold_on) AS next_amount
FROM sales
ORDER BY seller,
         sold_on;

-- Running total ต่อภูมิภาค

SELECT region,
       sold_on,
       amount,
       SUM(amount) OVER (PARTITION BY region
                         ORDER BY sold_on ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM sales
ORDER BY region,
         sold_on;

-- Top-N ต่อพาร์ทิชัน

SELECT *
FROM
  (SELECT region,
          seller,
          amount,
          ROW_NUMBER() OVER (PARTITION BY region
                             ORDER BY amount DESC) AS rn
   FROM sales) t
WHERE rn <= 2
ORDER BY region,
         rn;
