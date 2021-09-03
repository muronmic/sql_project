-- poèasí - k mìstu pøiøazuji stát, používám tabulku cities
-- Pro Kiev jsem v žádné tabulce nenašla údaj se stejným jménem 'Kiev', proto explicitnì pøiøazuji k tomuto mìstu stát.
-- Pøidávám iso3, abych mohla lépe pøiøazovat údaje ke stejným státùm (Czechia - Czech Republic, a podobné)

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
