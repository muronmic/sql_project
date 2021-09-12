# SQL Projekt

Zadáním projektu bylo vytvořit tabulku vycházející z tabulky covid19_basic_differences, která bude obsahovat informace o počtu nakažených lidí nemocí covid19 v různých zemích, o množství udělaných testů na covid19 a navíc časové proměnné, kulturní proměnné a v neposlední řadě také informace o počasí. Podrobné zadání naleznete [ZDE](zadani_projektu.md).

## Postup

V souborech, které jsou uloženy ve složce [sql_files](/sql_files), najdete mezikroky (tabulky), které jsem potřebovala k získání finální tabulky. Query dané tabulky naleznete i v postupu níže, vždy pod popisem dané tabulky.

### 1. t_base_time_variable

Jako první jsem vytvořila tabulku t_base_time_variable. Ta obsahuje následující sloupce:

* date, country, confirmed - tyto údaje jsou ze základní tabulky covid19_basic_differences,

* entity, tests_performed - tyto údaje jsou z tabulky covid19_tests získané pomocí LEFT JOIN,

* population, iso3 - tyto údaje, které jsem získala použitím klauzule LEFT JOIN, jsou z tabulky lookup_table a countries, 

* flag_weekend, season - časové údaje jsem získala použitím funkce CASE WHEN, kdy na základě sloupce date určuji, zda se jedná o víkend nebo ne a o jaké jde roční období.

Sloupec iso3 používám, abychom měli sloupec, který se narozdíl od jmen států v tabulkách neliší. Tento sloupec budeme později používat pro spojování tabulek.

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
  
### 2. t_base_without_dupl_tests

Bohužel v tabulce covid19_tests jsou u některých států pro jeden den dvě entity a tudíž dva údaje o provedených testech. Proto v naší první mezitabulce máme pro některé státy dvě stejná data s jinými údaji o provedených testech. Musíme se těchto řádků navíc zbavit, abychom měli pro každé datum a stát pouze jeden řádek.
Další tabulka t_base_without_dupl_tests tento problém řeší pomocí window funkce. Přednostně beru entity a k nim patřící počet provedených testů podle abecedy (tzn. people tested mají přednost před samples tested atd.)

Window funkci používám následovně ```RANK () OVER(PARTITION BY date, country ORDER BY entity )``` - pro každé různé datum a stát přiřadím rank a "grupuji" to podle entity. Díky tomu budou mít řádky přiřazený RANK 1 až N. Řádky, které mají opakující se datum a stát, ale jinou entitu, budou mít číslo vyšší než 1 a my se těchto řádků pomocí podmínky WHERE base.rnk = 1 zbavíme. 

<details><summary>t_base_without_dupl_tests</summary>
	
```	
-- Některé státy (např. Polsko) měly u provedených testů více údajů pro jeden den 
-- (například počet provedených testů pro entity people tested a entity units unclear), chceme se těchto "duplicit" zbavit
-- Přednostně budu brát údaje - entity podle abecedy (tzn. people tested mají přednost před samples tested atd.)
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
```
	
</details>

### 3 - 5. t_GDP_per_capita, t_gini, t_children_mortality

Dále jsem vytvořila tabulky o množství HDP na obyvatele - t_GDP_per_capita, o koeficientu gini - t_gini, a o dětské úmrtnosti - t_children_mortality, které vychází z tabulky economies.
Všechny tabulky obsahují sloupce country, iso3 a potom příslušný sloupec s požadovaným údajem (GDP_per_capita, gini, children_mortality). Údaj o iso3 jsem získala z tabulky countries použitím klauzule LEFT JOIN. Abych eliminovala chybějící data, tak jsem vzala vždy nejnovější údaj o GDP, gini a dětské úmrtnosti, pokud existoval, od roku 2010. Tzn. že některý stát bude mít údaj z roku 2018, některý z roku 2015 a některý nemusí mít žádný údaj, ale těch je minimum. 

<details><summary>t_GDP_per_capita</summary>
	
```
-- Mezitabulka pro HDP na obyvatele
-- Pokud země nemá údaj z roku 2020, vezmu ten nejnovější od roku 2010 (pokud nějaký je)


CREATE TABLE t_GDP_per_capita AS (
WITH base AS (
SELECT 	
	country,
	GDP,
	MAX(year)
FROM economies e 
WHERE GDP IS NOT NULL 
AND year >= 2010
GROUP BY country)
SELECT 
	c.iso3,
	base.country,
	ROUND(GDP / c.population, 2) AS GDP_per_capita
FROM base 
JOIN countries c ON base.country = c.country);
```
</details>

<details><summary>t_gini</summary>
	
```
-- GINI
-- Pokud země nemá údaj z roku 2020, vezmu ten nejnovější od roku 2010 (pokud nějaký je)

CREATE TABLE t_gini AS (
WITH base AS (
SELECT 
	country,
	gini,
	MAX(year)
FROM economies e 
WHERE gini IS NOT NULL 
AND year >= 2010
GROUP BY country)
SELECT 
	c.iso3,
	base.country,
	gini
FROM base
JOIN countries c ON c.country = base.country);	
```
</details>

<details><summary>t_children_mortality</summary>
	
```
-- Children mortality
-- Pokud země nemá údaj z roku 2020, vezmu ten nejnovější od roku 2010 (pokud nějaký je)

CREATE TABLE t_children_mortality AS (
WITH base AS (
SELECT 
	country,
	MAX(year),
	mortaliy_under5 AS children_mortality
FROM economies e
WHERE mortaliy_under5 IS NOT NULL 
AND year >= 2010
GROUP BY country) 
SELECT 
	c.iso3,
	base.country,
	base.children_mortality
FROM base
JOIN countries c ON base.country = c.country);	
```
</details>


### 6. t_religions

Informace o náboženství jsem vybrala z tabulky religions do tabulky t_religions, kde každé náboženství má svůj vlastní sloupec. Potřebovala jsem pro každý stát určit kolik procent populace patří k jakému náboženství.
Použila jsem v SELECT následující formuli pro každé náboženství: ```MAX(CASE WHEN religion = 'Christianity' THEN population END) Christianity```. Grupuju údaje podle státu a roku. Tímto způsobem dostanu údaje o náboženství do sloupce a můžu s tímto údajem dále pracovat - tj. vypočíst procento věřících pro každou zemi. Opět jsem použila LEFT JOIN s lookup_table a tabulkou countries, abych získala iso3 pro danou zemi. Funkci TRIM používám, protože se u některých států (Thaiwan) vyskytuje * před jménem státu. 

<details><summary>t_religions</summary>
	
```
-- Náboženství
-- Použila jsem LEFT JOIN s lookup_table a tabulkou countries a to kvůli iso3 - iso3 používám, protože 
-- některé státy se různě jmenují v různých tabulkách, ale iso3 zůstává stejné
-- Funkci TRIM používám, protože se u některých států (Thaiwan) vyskytuje * před jménem státu. 

CREATE TABLE t_religions AS (
WITH base AS (
SELECT 
	country,
	SUM(population) AS population,
	MAX(CASE WHEN religion = 'Christianity' THEN population END) Christianity,
	MAX(CASE WHEN religion = 'Islam' THEN population END) Islam,
	MAX(CASE WHEN religion = 'Unaffiliated Religions' THEN population END) Unaffiliated_Religions,
	MAX(CASE WHEN religion = 'Hinduism' THEN population END) Hinduism,
	MAX(CASE WHEN religion = 'Buddhism' THEN population END) Buddhism,
	MAX(CASE WHEN religion = 'Folk Religions' THEN population END) Folk_Religions,
	MAX(CASE WHEN religion = 'Other Religions' THEN population END) Other_Religions,
	MAX(CASE WHEN religion = 'Judaism' THEN population END) Judaism
FROM religions r 
WHERE year = 2020
GROUP BY country, year)
SELECT 
	base.country,
	CASE 
	WHEN c.iso3 IS NOT NULL THEN c.iso3
	WHEN lt.iso3 IS NOT NULL THEN lt.iso3
	ELSE NULL
	END AS iso3,
	base.population,
	ROUND(100 * Christianity / base.population, 2) AS Christianity,
	ROUND(100 * Islam / base.population, 2) AS Islam,
	ROUND(100 * Hinduism / base.population, 2) AS Hinduism,
	ROUND(100 * Buddhism / base.population, 2) AS Buddhism,
	ROUND(100 * Judaism / base.population, 2) AS Judaism,
	ROUND(100 * Folk_Religions / base.population) AS Folk_Religions,
	ROUND(100 * Other_Religions / base.population) AS Other_Religions,
	ROUND(100 * Unaffiliated_Religions / base.population) AS Unaffiliated_Religions
FROM base
LEFT JOIN lookup_table lt ON base.country = TRIM(TRAILING '*' FROM lt.country) AND lt.province IS NULL
LEFT JOIN countries c ON base.country = c.country OR lt.iso3 = c.iso3);	
```
</details>

### 7. t_life_expectancy_difference

Tabulka t_life_expectancy_difference ukazuje rozdíl dožití ve státě mezi lety 1965 a 2015. Vycházím z tabulky life_expectancy a používám LEFT JOIN s ní samou, abych mohla odečíst údaje mezi lety.

<details><summary>t_life_expectancy_difference</summary>
	
```
-- doba dožití 2015 - 1965

CREATE TABLE t_life_expectancy_difference AS (
SELECT 
	base.country,
	base.iso3,
	base.life_expectancy - le.life_expectancy AS life_expectancy_difference
FROM life_expectancy base
LEFT JOIN life_expectancy le ON base.country = le.country
WHERE le.year = 1965
AND base.year = 2015);	
```
</details>

### 8. t_raining_hours

Dále jsem vytvořila tabulky s informacemi o počasí, které jsem získala z tabulky weather. První z nich je t_raining_hours. Obsahuje údaj date, city a raining_hours (počet hodin, kdy byly srážky nenulové). Údaje o počasí jsou měřeny ve městě, proto budeme později k tomuto městu přiřazovat stát, abychom mohli tabulky spojit dohromady. 
Použila jsem ```CAST(date AS date) AS date```, jelikož údaje v tabulce weather obsahují jiný formát data než tabulka covid19_basic_differences. CAST AS jsem použila i pro další údaj: ```CAST(TRIM(TRAILING ' mm' FROM rain) AS FLOAT) AS rain```, zde jsem použila i funkci TRIM, protože bez odstranění mm bych dostávala upozornění, která by mi bránila ve vytvoření tabulky.
Nakonec jsem ještě použila funkci NULLIF a to následovně - ```COUNT(NULLIF(rain, 0))``` - NULLIF změní 0 na NULL a klauzule COUNT ignoruje NULL, tudíž můžu počítat pouze s nenulovými srážkami. Ve výpočtu hodin, kdy byly srážky nenulové, násobím 3, protože časové intervaly v tabulce weather jsou 3 hodiny. 

<details><summary>t_raining_hours</summary>
	
```
-- Počasí, počet hodin, kdy pršelo

-- Použití funkce TRIM - bez odstranění mm bych dostávala warnings, které by mi bránily ve vytvoření tabulky. 
-- Použití funkce CAST - chci, aby databáze pracovala s údajem jako s číslem, což budu potřebovat ve výpočtu níž. 
-- Ve výpočtu násobím 3, protože uvedené časové intervaly mají 3 hodiny. 
-- Použití NULLIF - změní 0 na NULL a count ignoruje NULL, tím pádem můžu počítat pouze s nenulovými srážkami.

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
```
</details>

### 9. t_daily_temp

Další údaj, který jsem potřebovala o počasí zjistit, je průměrná denní teplota (ne noční). Tabulka t_daily_temp obsahuje sloupce date, city a avg_daily_temp - tj. průměrná denní teplota mezi 6. a 18. hodinou. Opět jsem použila funkce CAST a TRIM, ze stejných důvodů jako u předešlé tabulky. Pro výpočet jsem použila agregační funkci AVG.

<details><summary>t_daily_temp</summary>
	
```
-- průměrná denní teplota - den od 06:00 do 18:00

-- Opět funkce TRIM

CREATE TABLE t_daily_temp AS (
WITH base AS (
SELECT 
	CAST(date AS date) AS date,
	city,
	TRIM(TRAILING ' °c' FROM temp) AS temperature
FROM weather
WHERE time IN ('06:00', '09:00', '12:00', '15:00', '18:00')
AND city IS NOT NULL)
SELECT 
	base.date,
	base.city,
	ROUND(AVG(CAST(base.temperature AS INT)), 2) AS avg_daily_temp
FROM base
GROUP BY date, city);	
```
</details>

### 10. t_max_daily_gust

Třetí tabulka týkající se počasí je t_max_daily_gust, která má v sobě údaje o datu, městě a maximální síle větru v nárazech za celý den. Opět používám CAST na datum (vycházím totiž stále z tabulky weather). A ze stejného důvodu jako u předešlé tabulky používám funkci TRIM a CAST na údaj o rychlosti větru a to následovně: ```CAST(TRIM(TRAILING ' km/h' FROM gust) AS INT)```. Pro výpočet jsem použila agregační funkci MAX. 

<details><summary>t_max_daily_gust</summary>
	
```
-- gust síla větru v nárazech
-- Opět používám funkci TRIM a CAST. 

CREATE TABLE t_max_daily_gust AS (
WITH base AS (
SELECT 
	CAST(date AS date) AS date,
	city,
	time,
	CAST(TRIM(TRAILING ' km/h' FROM gust) AS INT) AS gust
FROM weather)
SELECT 
	base.date,
	base.city,
	MAX(gust) AS max_daily_gust
FROM base
WHERE city IS NOT NULL
GROUP BY date, city);	
```
</details>

### 11. t_weather

Nyní jsem spojila pomocí LEFT JOIN všechny tři tabulky týkající se počasí do jedné tabulky t_weather. Tato tabulka bude tedy obsahovat sloupce date, city, raining_hours, max_daily_gust a raining_hours. Spojovala podle města a data. 

<details><summary>t_weather</summary>
	
```
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
```
</details>

### 12. t_weather_with_country

Jak jsem již dříve zmínila, je potřeba, aby se ke každému městu v tabulce o počasí přidal údaj, o jaký stát se jedná. K tomuto účelu používám tabulku cities. Pro město Kiev jsem v žádné tabulce nenašla údaj se stejným jménem 'Kiev', proto explicitně přiřazuji k tomuto městu stát 'Ukraine', jak můžete vidět v query níže. Pomocí LEFT JOIN s podmínkami ON base.city = c.city AND c.capital = 'primary' jsem získala tabulku t_weather_with_country s údajem o datu, městě, počasí a taky o iso3 a zemi. 

<details><summary>t_weather_with_country</summary>
	
```
-- počasí - k městu přiřazuji stát, používám tabulku cities
-- Pro Kiev jsem v žádné tabulce nenašla údaj se stejným jménem 'Kiev', proto explicitně přiřazuji k tomuto městu stát.
-- Přidávám iso3, abych mohla lépe přiřazovat údaje ke stejným státům (Czechia - Czech Republic, a podobné)

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
```
</details>

### 13 - 14. t_base_with_weather, t_base_add1

Nyní připojíme tabulku t_weather_with_country k tabulce t_base_without_dupl_tests. Budeme spojovat pomocí sloupců date, country a iso3. Tímto získáme tabulku t_base_with_weather.
K této tabulce dále připojíme informace o hustotě obyvatel (population_density) a mediánu věku obyvatel (median_age_2018) z tabulky countries a to opět pomocí LEFT JOIN (spojujeme podle iso3 a country). Tím získáme tabulku t_base_add1.


<details><summary>t_base_with_weather</summary>
	
```
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
```
</details>

<details><summary>t_base_add1</summary>
	
```
-- Přidání hustoty obyvatel a mediánu

CREATE TABLE t_base_add1 AS (
SELECT 
	t.*,
	c.population_density,
	c.median_age_2018 
FROM t_base_with_weather t
LEFT JOIN countries c ON t.iso3 = c.iso3 OR t.country = c.country
ORDER BY date);	
```
</details>

### 15. t_michaela_muronova_projekt_SQL_final

Posledním krokem k získání finální tabulky t_michaela_muronova_projekt_SQL_final je přidání k tabulce t_base_add1 informace získané z předešlých kroků.
Tabulku t_base_add1 tedy pomocí LEFT JOIN spojím s tabulkami t_GDP_per_capita, t_gini, t_children_mortality, t_life_expectancy_difference a t_religions. Abych spojila co nejvíc údajů a vyhla se NULL hodnotám, spojuji podle iso3 (proto jsem si tento údaj v tabulkách nechávala). Pro případ, že by údaj s iso3 v tabulce nebyl, přidávám možnost spojit tabulky i pomocí názvu country. V query zaokrouhluji údaje o hustotě obyvatel a rozdílu dožití na dvě desetinná místa. Výsledná tabulka má 24 sloupců s požadovanými údaji a je seřazena pomocí sloupců date a country.

* date - datum
* country - stát
* confirmed - počet potvrzených pozitivních covid19 případů
* tests_performed - počet provedených testů na covid19
* population - počet obyvatel v daném státě
* flag_weekend, season - časové proměnné 
* population_density, GDP_per_capita, gini, children_mortality, median_age_2018, Christianity, Islam, Hinduism, Buddhism, Judaism, Folk_Religions, Other_Religions, Unaffiliated_Religions, life_expectancy_difference - kulturní proměnné
* avg_daily_temp, raining_hours, max_daily_gust - počasí

<details><summary>t_michaela_muronova_projekt_SQL_final</summary>
	
```
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
```
</details>

## Chybějící data

Některé země (country), pro které máme v tabulce covid19_basic_differences příslušná data, jsem v dostupných tabulkách nenalezla žádné další informace - jedná se o Diamond Princess a MS Zaandam. 

Pro některé země nejsou naopak dostupná data v tabulce covid19_tests. V tabulce economies zase chybí data o HDP, gini a dětské úmrtnosti pro některé země - tam jsou buď starší než 11 let nebo nejsou dostupná vůbec - proto je taky ve výsledné tabulce nenajdeme. Stejný problém je i v tabulce religions. 

Tabulka weather obsahuje informace jenom o několika evropských městech, proto je také ve výsledné tabulce většina států bez informací o počasí. 

Obecně platí pro všechna chybějící data, že chybí z důvodu jejich absence v dostupných tabulkách. Díky používání iso3 jako identifikátu a spojování tabulek napříč podle sloupců country i iso3, jsme minimalizovali (snad úplně) chybějící údaje.  


## Problémy během vypracování projektu 

Jeden z prvních problémů, na který jsem narazila, byl dlouhý čas vykonávání query. 
Hned vytvoření první tabulky trvalo ze všech nejdéle. Na mé lokální databázi se tabulka vytvořila za 5-6 minut, ale když jsem později zkoušela vytvořit tabulku přímo na databázi od engeto, tak se tabulka vytvářela až 16 minut. U tabulek, které se vytvářely déle, jsem přidala komentář s délkou vytváření. 

Dalším problémem byly nejednotné názvy ve sloupci country napříč tabulkami, z tohoto důvodu jsem jako identifikátor používala iso3, jak jsem zmiňovala výše. Nejednotné názvy byly i ve městech (sloupec city) v tabulce weather. 

Dalším problémem bylo více záznamů o provedených testech v jeden den v tabulce covid19_tests, který jsem již popisovala výše. Všechny další konkrétní problémy jsem popsala v postupu. 
