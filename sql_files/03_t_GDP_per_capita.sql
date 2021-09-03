-- Mezitabulka pro HDP na obyvatele
-- Pokud země nemá údaj z roku 2020, vezmu ten nejnovější od roku 2010 (pokud nějaký je)


CREATE TABLE t_GDP_per_capita AS (
WITH base AS (
SELECT 	
	country,
	GDP,
	MAX(year)
FROM economies e 
WHERE GDP IS NOT NULL 
AND year >= 2010
GROUP BY country)
SELECT 
	c.iso3,
	base.country,
	ROUND(GDP / c.population, 2) AS GDP_per_capita
FROM base 
JOIN countries c ON base.country = c.country);

