-- Počet nakažených a počet provedených testů v zemi v nejteplejší den

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

-- Největší počet nakažených pro každou zemi + v jaký den to bylo 

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

-- Počet nakažených a počet provedených testů po dnech v zemích, kde je nejvíce křesťanů (více než 75 %)

SELECT 
	date,
	country,
	confirmed,
	tests_performed
FROM t_michaela_muronova_projekt_sql_final 
WHERE Christianity >= 75;

-- Největší denní nárůst nakažených v zemi pro každé roční období

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

-- Průběh počtu nakažených a provedených testů pro země s nízkou hodnotou HDP na obyvatele

SELECT 
	date,
	country,
	confirmed,
	tests_performed 	
FROM t_michaela_muronova_projekt_sql_final tmmpsf 
WHERE GDP_per_capita < 1000;

-- Průběh počtu nakažených a provedených testů pro země s vysokým rozdílem dožití v letech 1965 a 2015

SELECT 
	date,
	country,
	confirmed,
	tests_performed 	
FROM t_michaela_muronova_projekt_sql_final tmmpsf 
WHERE life_expectancy_difference > 25;

-- Průběh počtu nakažených a provedených testů pro země s vysokou hustotou zalidnění (> 1000)

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


