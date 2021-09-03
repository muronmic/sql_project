-- konečná tabulka

-- Používám LEFT JOIN ke spojení tabulek dohromady, spojuji pomocí iso3, které jsem si v tabulkách naschvál nechávala po celou dobu,
-- pro případ, že by údaj s iso3 v tabulce nebyl, přidávám možnost spojit tabulky i pomocí názvu country.
-- Zaokrouhluji údaje o hustotě obyvatel a rozdílu dožití na dvě desetinná místa.
-- Tabulka se vytvoří na databázi od engeto za 1.5 minuty.

CREATE TABLE t_michaela_muronova_projekt_SQL_final AS (
SELECT 
	base.date,
	base.country,
	base.confirmed,
	base.tests_performed,
	base.population,
	base.flag_weekend,
	base.season,
	ROUND(base.population_density, 2) AS population_density,
	gdp.GDP_per_capita,
	tg.gini,
	mort.children_mortality,
	base.median_age_2018,
	reli.Christianity,
	reli.Islam,
	reli.Hinduism,
	reli.Buddhism,
	reli.Judaism,
	reli.Folk_Religions,
	reli.Other_Religions,
	reli.Unaffiliated_Religions,	
	ROUND(tled.life_expectancy_difference, 2) AS life_expectancy_difference,
	base.avg_daily_temp,
	base.raining_hours,
	base.max_daily_gust
FROM t_base_add1 base
LEFT JOIN t_GDP_per_capita gdp ON base.iso3 = gdp.iso3 OR base.country = gdp.country
LEFT JOIN t_gini tg ON base.iso3 = tg.iso3 OR base.country = tg.country 
LEFT JOIN t_children_mortality mort ON base.iso3 = mort.iso3 OR base.country = mort.country
LEFT JOIN t_life_expectancy_difference tled ON base.iso3 = tled.iso3 OR base.country = tled.country
LEFT JOIN t_religions reli ON base.iso3 = reli.iso3 OR base.country = reli.country)
ORDER BY base.date, base.country;
