-- Prvn� mezitabulka, ukazuje �asov� prom�nn� - pomoc� CASE WHEN ukazuje, zda se jedn� o v�kend nebo ne.
-- Funkci CASE WHEN pou��v�m i pro zobrazen� ro�n�ho obdob� (jaro - 0, l�to - 1 atd.)
-- CASE WHEN je pou�ito i pro populaci a to kv�li tomu, �e v ka�d� tabulce se st�ty jmenuj� jinak a t�mto zp�sobem napasujeme v�echny.
-- Sloupec iso3 pou��v�m, abychom m�li sloupec, kter� se narozd�l od jmen st�t� v tabulk�ch neli��, tento sloupec budeme
-- pozd�ji pou��vat pro spojov�n� tabulek.


-- !! Tento SELECT proch�z� na datab�zi od engeto 16-17 minut
-- Na m�m localhostu se tabulka vytvo�ila za 5-6 minut.

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
LEFT JOIN lookup_table lt ON (base.country = lt.country
	AND lt.province IS NULL)
LEFT JOIN covid19_tests ct
	ON (lt.iso3 = ct.ISO 
	AND base.date = ct.date)
LEFT JOIN countries c ON lt.iso3 = c.iso3
ORDER BY country);