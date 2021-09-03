-- Náboženství
-- Použila jsem LEFT JOIN s lookup_table a tabulkou countries a to kvùli iso3 - iso3 používám, protože 
-- nìkteré státy se rùznì jmenují v rùzných tabulkách, ale iso3 zùstává stejné
-- Funkci TRIM používám, protože se u nìkterých státù (Thaiwan) vyskytuje * pøed jménem státu. 

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
LEFT JOIN countries c ON base.country = c.country OR lt.iso3 = c.iso3);
