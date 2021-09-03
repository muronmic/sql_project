-- Nìkteré státy (napø. Polsko) mìly u provedených testù více údajù pro jeden den 
-- (napøíklad poèet provedených testù pro entity people tested a entity units unclear), chceme se tìchto "duplicit" zbavit
-- Pøednostnì budu brát údaje - entity podle abecedy (tzn. people tested mají pøednost pøed samples tested atd.)
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