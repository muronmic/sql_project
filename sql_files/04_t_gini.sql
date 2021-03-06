-- GINI
-- Pokud země nemá údaj z roku 2020, vezmu ten nejnovější od roku 2010 (pokud nějaký je)

CREATE TABLE t_gini AS (
WITH base AS (
SELECT 
	country,
	gini,
	MAX(year)
FROM economies e 
WHERE gini IS NOT NULL 
AND year >= 2010
GROUP BY country)
SELECT 
	c.iso3,
	base.country,
	gini
FROM base
JOIN countries c ON c.country = base.country);
