-- Children mortality
-- Pokud zemì nemá údaj z roku 2020, vezmu ten nejnovìjší od roku 2010 (pokud nìjaký je)

CREATE TABLE t_children_mortality AS (
WITH base AS (
SELECT 
	country,
	MAX(year),
	mortaliy_under5 AS children_mortality
FROM economies e
WHERE mortaliy_under5 IS NOT NULL 
AND year >= 2010
GROUP BY country) 
SELECT 
	c.iso3, 
	base.children_mortality
FROM base
JOIN countries c ON base.country = c.country);