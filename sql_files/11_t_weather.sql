-- Počasí spojené dohromady 
-- Tento SELECT prochází za cca 3 minuty na databázi od engeto (opět na localhostu rychleji a to do 1 minuty)

CREATE TABLE t_weather AS (
SELECT 
	dt.*,
	tmdg.max_daily_gust,
	rh.raining_hours 
FROM t_daily_temp dt
LEFT JOIN t_max_daily_gust tmdg ON dt.date = tmdg.date AND dt.city = tmdg.city 
LEFT JOIN t_raining_hours rh ON dt.date = rh.date AND dt.city = rh.city
ORDER BY date);
