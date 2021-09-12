## SQL Projekt

Zadáním projektu bylo vytvořit tabulku vycházející z tabulky covid19_basic_differences, která bude obsahovat informace o počtu nakažených lidí nemocí covid19 v různých zemích, o množství udělaných testů na covid19 a navíc časové proměnné, kulturní proměnné a v neposlední řadě také informace o počasí. Podrobné zadání naleznete ZDE.

<details><summary>t_base_time_variable</summary>

```
-- První mezitabulka, ukazuje časové proměnné - pomocí CASE WHEN ukazuje, zda se jedná o víkend nebo ne.
-- Funkci CASE WHEN používám i pro zobrazení ročního období (jaro - 0, léto - 1 atd.)
-- CASE WHEN je použito i pro populaci a to kvůli tomu, že v každé tabulce se státy jmenují jinak a tímto způsobem napasujeme všechny.
-- Sloupec iso3 používám, abychom měli sloupec, který se narozdíl od jmen států v tabulkách neliší, tento sloupec budeme
-- později používat pro spojování tabulek.


-- !! Tento SELECT prochází na databázi od engeto 16-17 minut
-- Na mém localhostu se tabulka vytvořila za 5-6 minut.

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
  ```
  </details>
  
  
  Pokračování normálního textu
 Změnyyyyy
  
