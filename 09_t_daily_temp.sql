-- prùmìrná denní teplota - den od 06:00 do 18:00

-- Opìt funkce TRIM

CREATE TABLE t_daily_temp AS (
WITH base AS (
SELECT 
	CAST(date AS date) AS date,
	city,
	TRIM(TRAILING ' °c' FROM temp) AS temperature
FROM weather
WHERE time IN ('06:00', '09:00', '12:00', '15:00', '18:00')
AND city IS NOT NULL)
SELECT 
	base.date,
	base.city,
	ROUND(AVG(CAST(base.temperature AS INT)), 2) AS avg_daily_temp
FROM base
GROUP BY date, city);