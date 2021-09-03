-- K základní tabulce t_base_without_dupl_tests pøidávám informace s poèasím

CREATE TABLE t_base_with_weather AS (
SELECT 
	base.*,
	t.avg_daily_temp,
	t.max_daily_gust,
	t.raining_hours
FROM t_base_without_dupl_tests base 
LEFT JOIN t_weather_with_country t ON base.date = t.date AND (base.country = t.country OR base.iso3 = t.iso3)
ORDER BY date);