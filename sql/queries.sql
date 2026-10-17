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