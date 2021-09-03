-- Poèasí, poèet hodin, kdy pršelo

-- Použití funkce TRIM - bez odstranìní mm bych dostávala warnings, které by mi bránily ve vytvoøení tabulky. 
-- Použití funkce CAST - chci, aby databáze pracovala s údajem jako s èíslem, což budu potøebovat ve výpoètu níž. 
-- Ve výpoètu násobím 3, protože uvedené èasové intervaly mají 3 hodiny. 
-- Použití NULLIF - zmìní 0 na NULL a count ignoruje NULL, tím pádem mùžu poèítat pouze s nenulovými srážkami.

CREATE TABLE t_raining_hours AS (
WITH base AS (
SELECT 
	CAST(date AS date) AS date,
	time,
	city,
	CAST(TRIM(TRAILING ' mm' FROM rain) AS FLOAT) AS rain
FROM weather
WHERE city IS NOT NULL)
SELECT 
	base.date,
	-- base.time,
	base.city,
	-- base.rain,
	3 * count(NULLIF(rain, 0)) AS raining_hours
FROM base
GROUP BY date, city);