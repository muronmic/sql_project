-- K základní tabulce t_base_without_dupl_tests přidávám informace s počasím
-- Tento SELECT opět prochází delší dobu - na databázi od engeto se tabulka vytvořila za 10 minut (na localhostu za 2.5 minuty).

CREATE TABLE t_base_with_weather AS (
SELECT 
	base.*,
	t.avg_daily_temp,
	t.max_daily_gust,
	t.raining_hours
FROM t_base_without_dupl_tests base 
LEFT JOIN t_weather_with_country t ON base.date = t.date AND (base.country = t.country OR base.iso3 = t.iso3)
ORDER BY date);
