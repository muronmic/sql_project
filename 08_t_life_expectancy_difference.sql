-- doba dožití 2015 - 1965

CREATE TABLE t_life_expectancy_difference AS (
SELECT 
	base.country,
	base.iso3,
	base.life_expectancy - le.life_expectancy AS life_expectancy_difference
FROM life_expectancy base
LEFT JOIN life_expectancy le ON base.country = le.country
WHERE le.year = 1965
AND base.year = 2015);
