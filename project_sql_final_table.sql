-- První mezitabulka, podmínky u populace a iso3 jsou kvuli tomu,
-- že některé státy se jmenují jinak v rùzných tabulkách, proto je chci napasovat
-- Tento select prochází hodně dlouho

CREATE TABLE t_base_time_variable AS (
SELECT 
	base.date,
	base.country,
	base.confirmed,
	ct.entity,
	ct.tests_performed,
	CASE WHEN lt.population IS NOT NULL THEN lt.population 
	ELSE c.population END AS population,
	CASE WHEN lt.iso3 IS NULL THEN c.iso3 ELSE lt.iso3 END AS iso3,
	CASE WHEN WEEKDAY(base.date) IN (5, 6) THEN 1
	ELSE 0
	END AS flag_weekend,
	CASE
	WHEN MONTH(base.date) IN (3, 4, 5) THEN 0
	WHEN MONTH(base.date) IN (6, 7, 8) THEN 1
	WHEN MONTH(base.date) IN (9, 10, 11) THEN 2
	WHEN MONTH(base.date) IN (12, 1, 2) THEN 3
	END AS season	
FROM covid19_basic_differences base
LEFT JOIN lookup_table lt ON base.country = lt.country
	AND lt.province IS NULL
LEFT JOIN covid19_tests ct
	ON lt.iso3 = ct.ISO 
	AND base.date = ct.date
LEFT JOIN countries c ON lt.iso3 = c.iso3
ORDER BY country);

SELECT DISTINCT entity FROM `data`.covid19_tests ORDER BY entity ;


-- Některé státy měly u provedených testů více údajů pro jeden den, chceme se těchto "duplicit" zbavit
-- Přednostnì budu brát údaje - entity podle abecedy (SELECT DISTINCT entity FROM `data`.covid19_tests ORDER BY entity ;)

CREATE TABLE t_base_without_dupl_tests AS (
WITH base AS (
SELECT 	
	*,
	RANK () OVER(PARTITION BY date, country ORDER BY entity ) rnk
FROM t_base_time_variable)
SELECT 
	base.date,
	base.country,
	base.confirmed,
	base.tests_performed,
	base.population,
	base.iso3,
	base.flag_weekend,
	base.season
FROM base
WHERE base.rnk = 1);

-- Mezitabulky pro HDP, GINI a children_mortality
-- Pokud země nemá údaj z roku 2020, vezmu ten nejnovější od roku 2010 (pokud nějaký je)

-- HDP na obyvatele 

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
	ROUND(GDP / c.population, 2) AS GDP_per_capita
FROM base 
JOIN countries c ON base.country = c.country);


-- GINI

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
	gini
FROM base
JOIN countries c ON c.country = base.country);

-- Children mortality

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

-- Náboženství - otázka - mám tam dávat všechna náboženství nebo stačí jenom ta nejčastější? 

CREATE TABLE t_religions AS (
WITH base AS (
SELECT 
	country,
	SUM(population) AS population,
	MAX(CASE WHEN religion = 'Christianity' THEN population END) Christianity,
	MAX(CASE WHEN religion = 'Islam' THEN population END) Islam,
	MAX(CASE WHEN religion = 'Unaffiliated Religions' THEN population END) Unaffiliated_Religions,
	MAX(CASE WHEN religion = 'Hinduism' THEN population END) Hinduism,
	MAX(CASE WHEN religion = 'Buddhism' THEN population END) Buddhism,
	MAX(CASE WHEN religion = 'Folk Religions' THEN population END) Folk_Religions,
	MAX(CASE WHEN religion = 'Other Religions' THEN population END) Other_Religions,
	MAX(CASE WHEN religion = 'Judaism' THEN population END) Judaism
FROM religions r 
WHERE year = 2020
GROUP BY country, year)
SELECT 
	base.country,
	CASE 
	WHEN c.iso3 IS NOT NULL THEN c.iso3
	WHEN lt.iso3 IS NOT NULL THEN lt.iso3
	ELSE NULL
	END AS iso3,
	base.population,
	ROUND(100 * Christianity / base.population, 2) AS Christianity,
	ROUND(100 * Islam / base.population, 2) AS Islam,
	ROUND(100 * Hinduism / base.population, 2) AS Hinduism,
	ROUND(100 * Buddhism / base.population, 2) AS Buddhism,
	ROUND(100 * Judaism / base.population, 2) AS Judaism,
	ROUND(100 * Folk_Religions / base.population) AS Folk_Religions,
	ROUND(100 * Other_Religions / base.population) AS Other_Religions,
	ROUND(100 * Unaffiliated_Religions / base.population) AS Unaffiliated_Religions
FROM base
LEFT JOIN lookup_table lt ON base.country = TRIM(TRAILING '*' FROM lt.country) AND lt.province IS NULL
LEFT JOIN countries c ON base.country = c.country OR lt.iso3 = c.iso3)
;

-- počasí 
-- použití NULLIF - změní 0 na NULL a count ignoruje NULL 
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

-- gust síla větru v nárazech
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

-- průměrná denní teplota - den od 06:00 do 18:00

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

-- počasí dohromady 

CREATE TABLE t_weather AS (
SELECT 
	dt.*,
	tmdg.max_daily_gust,
	rh.raining_hours 
FROM t_daily_temp dt
LEFT JOIN t_max_daily_gust tmdg ON dt.date = tmdg.date AND dt.city = tmdg.city 
LEFT JOIN t_raining_hours rh ON dt.date = rh.date AND dt.city = rh.city
ORDER BY date);

-- počasí k místu přiřazuji stát, používám tabulku cities - nevadí to? 

CREATE TABLE t_weather_with_country_2 AS (
SELECT
	CASE WHEN c.country IS NOT NULL THEN c.country 
	WHEN base.city = 'Kiev' THEN 'Ukraine' 
	ELSE NULL END
	AS country,
	c.iso3,
	base.*
FROM t_weather base 
LEFT JOIN cities c ON base.city = c.city AND c.capital = 'primary');

-- k základní tabulce přidávám počasí

CREATE TABLE t_base_with_weather AS (
SELECT 
	base.*,
	t.avg_daily_temp,
	t.max_daily_gust,
	t.raining_hours
FROM t_base_without_dupl_tests base 
LEFT JOIN t_weather_with_country_2 t ON base.date = t.date AND (base.country = t.country OR base.iso3 = t.iso3)
ORDER BY date);

-- Přidání hustoty obyvatel a mediánu

CREATE TABLE t_base_add1 AS (
SELECT 
	t.*,
	c.population_density,
	c.median_age_2018 
FROM t_base_with_weather t
LEFT JOIN countries c ON t.iso3 = c.iso3 OR t.country = c.country
ORDER BY date);

-- konečná tabulka

CREATE TABLE t_michaela_muronova_projekt_SQL_final AS (
SELECT 
	base.date,
	base.country,
	base.confirmed,
	base.tests_performed,
	base.population,
	base.flag_weekend,
	base.season,
	ROUND(base.population_density, 2) AS population_density,
	gdp.GDP_per_capita,
	tg.gini,
	mort.children_mortality,
	base.median_age_2018,
	reli.Christianity,
	reli.Islam,
	reli.Hinduism,
	reli.Buddhism,
	reli.Judaism,
	reli.Folk_Religions,
	reli.Other_Religions,
	reli.Unaffiliated_Religions,	
	ROUND(tled.life_expectancy_difference, 2) AS life_expectancy_difference,
	base.avg_daily_temp,
	base.raining_hours,
	base.max_daily_gust
FROM t_base_add1 base
LEFT JOIN t_GDP_per_capita gdp ON base.iso3 = gdp.iso3 OR base.country = gdp.country
LEFT JOIN t_gini tg ON base.iso3 = tg.iso3 OR base.country = tg.country 
LEFT JOIN t_children_mortality mort ON base.iso3 = mort.iso3 OR base.country = mort.country
LEFT JOIN t_life_expectancy_difference tled ON base.iso3 = tled.iso3 OR base.country = tled.country
LEFT JOIN t_religions reli ON base.iso3 = reli.iso3 OR base.country = reli.country)
ORDER BY base.date, base.country;
