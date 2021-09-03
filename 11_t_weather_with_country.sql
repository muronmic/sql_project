-- po�as� - k m�stu p�i�azuji st�t, pou��v�m tabulku cities
-- Pro Kiev jsem v ��dn� tabulce nena�la �daj se stejn�m jm�nem 'Kiev', proto explicitn� p�i�azuji k tomuto m�stu st�t.
-- P�id�v�m iso3, abych mohla l�pe p�i�azovat �daje ke stejn�m st�t�m (Czechia - Czech Republic, a podobn�)

CREATE TABLE t_weather_with_country AS (
SELECT
	CASE WHEN c.country IS NOT NULL THEN c.country 
	WHEN base.city = 'Kiev' THEN 'Ukraine' 
	ELSE NULL END
	AS country,
	c.iso3,
	base.*
FROM t_weather base 
LEFT JOIN cities c ON base.city = c.city AND c.capital = 'primary');
