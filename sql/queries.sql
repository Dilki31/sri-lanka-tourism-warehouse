-- Query 1: each market's share of the top-20 total
SELECT c.country_name,
       f.tourists_ytd,
       ROUND(100.0 * f.tourists_ytd / SUM(f.tourists_ytd) OVER (), 1) AS pct_of_top20
FROM fact_arrivals_ytd AS f
JOIN dim_country AS c ON c.country_key = f.country_key
ORDER BY f.tourists_ytd DESC;

-- Query 2: tourists by region
SELECT c.region,
       COUNT(*)                AS markets,
       SUM(f.tourists_ytd)     AS tourists_ytd,
       ROUND(100.0 * SUM(f.tourists_ytd) / SUM(SUM(f.tourists_ytd)) OVER (), 1) AS pct_of_top20
FROM fact_arrivals_ytd AS f
JOIN dim_country AS c ON c.country_key = f.country_key
GROUP BY c.region
ORDER BY tourists_ytd DESC;

-- Query 3: running total, how many markets make up most of the arrivals
SELECT f.source_rank,
       c.country_name,
       f.tourists_ytd,
       SUM(f.tourists_ytd) OVER (ORDER BY f.source_rank) AS running_total,
       ROUND(100.0 * SUM(f.tourists_ytd) OVER (ORDER BY f.source_rank)
             / SUM(f.tourists_ytd) OVER (), 1) AS cumulative_pct
FROM fact_arrivals_ytd AS f
JOIN dim_country AS c ON c.country_key = f.country_key
ORDER BY f.source_rank;
-- Query 4: monthly arrivals derived from cumulative figures with LAG
WITH ytd AS (
    SELECT c.country_name,
           d.full_date,
           d.month,
           f.tourists_ytd,
           LAG(f.tourists_ytd) OVER (PARTITION BY f.country_key ORDER BY d.full_date) AS prev_ytd,
           LAG(d.month)        OVER (PARTITION BY f.country_key ORDER BY d.full_date) AS prev_month
    FROM fact_arrivals_ytd AS f
    JOIN dim_country AS c ON c.country_key = f.country_key
    JOIN dim_date    AS d ON d.date_key    = f.date_key
)
SELECT country_name,
       full_date,
       CASE WHEN month = 1              THEN tourists_ytd
            WHEN prev_month = month - 1 THEN tourists_ytd - prev_ytd
       END AS monthly_arrivals
FROM ytd
WHERE month = 1 OR prev_month = month - 1
ORDER BY full_date, monthly_arrivals DESC;