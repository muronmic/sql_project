-- gust síla vìtru v nárazech
-- Opìt používám funkci TRIM a CAST. 

CREATE TABLE t_max_daily_gust AS (
WITH base AS (
SELECT 
	CAST(date AS date) AS date,
	city,
	time,
	CAST(TRIM(TRAILING ' km/h' FROM gust) AS INT) AS gust
FROM weather)
SELECT 
	base.date,
	base.city,
	MAX(gust) AS max_daily_gust
FROM base
WHERE city IS NOT NULL
GROUP BY date, city);