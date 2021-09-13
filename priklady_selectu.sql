-- Po�et naka�en�ch a po�et proveden�ch test� v zemi v nejteplej�� den

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

-- Nejv�t�� po�et naka�en�ch pro ka�dou zemi + v jak� den to bylo 

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

-- Po�et naka�en�ch a po�et proveden�ch test� po dnech v zem�ch, kde je nejv�ce k�es�an� (v�ce ne� 75 %)

SELECT 
	date,
	country,
	confirmed,
	tests_performed
FROM t_michaela_muronova_projekt_sql_final 
WHERE Christianity >= 75;

-- Nejv�t�� denn� n�r�st naka�en�ch v zemi pro ka�d� ro�n� obdob�

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

-- Pr�b�h po�tu naka�en�ch a proveden�ch test� pro zem� s n�zkou hodnotou HDP na obyvatele

SELECT 
	date,
	country,
	confirmed,
	tests_performed 	
FROM t_michaela_muronova_projekt_sql_final tmmpsf 
WHERE GDP_per_capita < 1000;

-- Pr�b�h po�tu naka�en�ch a proveden�ch test� pro zem� s vysok�m rozd�lem do�it� v letech 1965 a 2015

SELECT 
	date,
	country,
	confirmed,
	tests_performed 	
FROM t_michaela_muronova_projekt_sql_final tmmpsf 
WHERE life_expectancy_difference > 25;

-- Pr�b�h po�tu naka�en�ch a proveden�ch test� pro zem� s vysokou hustotou zalidn�n� (> 1000)

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


