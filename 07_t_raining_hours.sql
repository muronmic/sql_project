-- Po�as�, po�et hodin, kdy pr�elo

-- Pou�it� funkce TRIM - bez odstran�n� mm bych dost�vala warnings, kter� by mi br�nily ve vytvo�en� tabulky. 
-- Pou�it� funkce CAST - chci, aby datab�ze pracovala s �dajem jako s ��slem, co� budu pot�ebovat ve v�po�tu n�. 
-- Ve v�po�tu n�sob�m 3, proto�e uveden� �asov� intervaly maj� 3 hodiny. 
-- Pou�it� NULLIF - zm�n� 0 na NULL a count ignoruje NULL, t�m p�dem m��u po��tat pouze s nenulov�mi sr�kami.

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