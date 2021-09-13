-- Poèet nakažených a poèet provedených testù v zemi v nejteplejší den

WITH base AS (
SELECT
	*, 
	MAX(avg_daily_temp) OVER (PARTITION BY country) AS max_temp
FROM t_michaela_muronova_projekt_sql_final)
SELECT 
	country,
	date,
	confirmed,
	tests_performed,
	avg_daily_temp
FROM base
WHERE avg_daily_temp = max_temp;

-- Nejvìtší poèet nakažených pro každou zemi + v jaký den to bylo 

WITH base AS (
SELECT
	*, 
	MAX(confirmed) OVER (PARTITION BY country) AS max_confirmed
FROM t_michaela_muronova_projekt_sql_final)
SELECT 
	country,
	date,
	confirmed AS nejvyssi_prirustek
FROM base
WHERE confirmed = base.max_confirmed
ORDER BY nejvyssi_prirustek DESC;

-- Poèet nakažených a poèet provedených testù po dnech v zemích, kde je nejvíce køesanù (více než 75 %)

SELECT 
	date,
	country,
	confirmed,
	tests_performed
FROM t_michaela_muronova_projekt_sql_final 
WHERE Christianity >= 75;

-- Nejvìtší denní nárùst nakažených v zemi pro každé roèní období

WITH base AS (
SELECT
	*, 
	MAX(confirmed) OVER (PARTITION BY country, season) AS max_confirmed
FROM t_michaela_muronova_projekt_sql_final)
SELECT 
	country,
	date,
	season,
	confirmed AS nejvyssi_prirustek
FROM base
WHERE confirmed = base.max_confirmed;

-- Prùbìh poètu nakažených a provedených testù pro zemì s nízkou hodnotou HDP na obyvatele

SELECT 
	date,
	country,
	confirmed,
	tests_performed 	
FROM t_michaela_muronova_projekt_sql_final tmmpsf 
WHERE GDP_per_capita < 1000;

-- Prùbìh poètu nakažených a provedených testù pro zemì s vysokým rozdílem dožití v letech 1965 a 2015

SELECT 
	date,
	country,
	confirmed,
	tests_performed 	
FROM t_michaela_muronova_projekt_sql_final tmmpsf 
WHERE life_expectancy_difference > 25;

-- Prùbìh poètu nakažených a provedených testù pro zemì s vysokou hustotou zalidnìní (> 1000)

SELECT 
	date,
	country,
	confirmed,
	tests_performed 	
FROM t_michaela_muronova_projekt_sql_final tmmpsf 
WHERE population_density > 1000;

-- Informace z tabulky t_michaela_muronova_projekt_sql_final pro den 30.8.2020

SELECT 
	*
FROM t_michaela_muronova_projekt_sql_final
WHERE date = '2020-08-30';


