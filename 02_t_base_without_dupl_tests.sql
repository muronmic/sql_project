-- N�kter� st�ty (nap�. Polsko) m�ly u proveden�ch test� v�ce �daj� pro jeden den 
-- (nap��klad po�et proveden�ch test� pro entity people tested a entity units unclear), chceme se t�chto "duplicit" zbavit
-- P�ednostn� budu br�t �daje - entity podle abecedy (tzn. people tested maj� p�ednost p�ed samples tested atd.)
-- people tested
-- people tested (incl. non-PCR)
-- samples tested
-- tests performed
-- tests performed (incl. non-PCR)
-- units unclear
-- units unclear (incl. non-PCR)

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