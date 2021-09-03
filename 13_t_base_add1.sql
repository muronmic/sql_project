-- Pøidání hustoty obyvatel a mediánu

CREATE TABLE t_base_add1 AS (
SELECT 
	t.*,
	c.population_density,
	c.median_age_2018 
FROM t_base_with_weather t
LEFT JOIN countries c ON t.iso3 = c.iso3 OR t.country = c.country
ORDER BY date);