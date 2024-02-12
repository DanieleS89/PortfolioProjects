-- Quick CHECK

SELECT TOP 100 *
FROM PortfolioProject..deaths

SELECT TOP 100 *
FROM PortfolioProject..vaccinations


-- Selecting specific data 

SELECT 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM PortfolioProject..deaths
ORDER BY 1,2



-- CHECK for nvarchar

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'deaths' AND (COLUMN_NAME = 'total_deaths' OR COLUMN_NAME = 'total_cases');
-- La query ci dice che entrambe sono nvarchar e quindi dobbiamo modificarle




-- Calculating LETHALITY

SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    CAST((total_deaths * 100.0 / NULLIF(total_cases, 0)) AS DECIMAL(10, 2)) AS Lethality
FROM deaths
ORDER BY 1, 2;






-- Showing Countries MORTALITY

SELECT 
	location, 
	MAX(Total_deaths) AS TotalDeathCount, 
	MAX((Total_deaths/population))*100 AS Mortality
FROM PortfolioProject..Deaths
GROUP BY location
ORDER BY Mortality DESC


-- Warning: the data in the “continent” and “location” columns have inconsistencies. 
-- “Continent” appears to be inaccurate, while “location” seems to be correct. 
-- Example: “continent North America” corresponds to “location United States,” so North America does not include data for Canada. 
-- Therefore, we cannot rely on “continent.” We must use “location” as a reference.



--  Calculating LETHALITY (creating a CTE)

WITH MaxValues AS (
    SELECT 
        location, 
        MAX(total_deaths) AS max_deaths, 
        MAX(total_cases) AS max_cases
    FROM deaths
    WHERE location IN ('Asia', 'Europe', 'North America', 'South America', 'Oceania', 'Africa')
    GROUP BY location, population
)
SELECT 
    location,
    max_deaths,
    max_cases,
    CAST(max_deaths AS DECIMAL) * 100.0 / CAST(max_cases AS DECIMAL) AS lethality
FROM MaxValues
ORDER BY location DESC;

-- Calculating MORTALITY (creating a CTE)

WITH MaxValues AS (
    SELECT 
        location, population, 
        MAX(total_deaths) AS max_deaths
    FROM deaths
    WHERE location IN ('Asia', 'Europe', 'North America', 'South America', 'Oceania', 'Africa')
    GROUP BY location, population
)
SELECT 
    location,
	population,
    max_deaths,
	CAST(max_deaths AS DECIMAL) * 100.0 / CAST(population AS DECIMAL) AS mortality
FROM MaxValues
ORDER BY location DESC;

-- Calculating INCIDENCE (creating a CTE)

WITH MaxValues AS (
    SELECT 
        location, 
		population, 
		MAX(total_cases) AS max_cases
    FROM deaths
    WHERE location IN ('Asia', 'Europe', 'North America', 'South America', 'Oceania', 'Africa')
    GROUP BY location, population
)
SELECT 
    location,
	population,
    max_cases,
	CAST(max_cases AS DECIMAL) * 100.0 / CAST(population AS DECIMAL) AS incidence
FROM MaxValues
ORDER BY location DESC;


-- Putting all together (Lethality, Mortality, Incidence) By Continent (creating a CTE)

WITH MaxValues AS (
    SELECT 
        location, population, 
        MAX(total_deaths) AS max_deaths, 
        MAX(total_cases) AS max_cases
    FROM deaths
    WHERE location IN ('Asia', 'Europe', 'North America', 'South America', 'Oceania', 'Africa')
    GROUP BY location, population
)
SELECT 
    location,
	population,
    max_deaths,
    max_cases,
    CAST(max_deaths AS DECIMAL) * 100.0 / CAST(max_cases AS DECIMAL) AS lethality,
	CAST(max_deaths AS DECIMAL) * 100.0 / CAST(population AS DECIMAL) AS mortality,
	CAST(max_cases AS DECIMAL) * 100.0 / CAST(population AS DECIMAL) AS incidence
FROM MaxValues
ORDER BY location DESC;



-- JOIN deaths and vaccinations table for quick analysis

SELECT *
FROM PortfolioProject..deaths dea
JOIN PortfolioProject..vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date


-- JOIN and calculating vaccinations RATE

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..deaths dea
JOIN PortfolioProject..vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != '' AND vac.new_vaccinations != ''
ORDER BY 1,2,3


-- Use PARTITION BY in order to get updated values day by day

SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(decimal, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationsUpdate
FROM PortfolioProject..deaths dea
JOIN PortfolioProject..vaccinations vac		
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != '' AND vac.new_vaccinations != ''
ORDER BY 2,3


-- Calculating Vaccination RATE (using CTE), (with date history)

WITH VaccinatedPopulation (Continent, Location, Date, Population, New_vaccinations, VaccinationsUpdate)
AS
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(decimal, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationsUpdate
	FROM PortfolioProject..deaths dea
	JOIN PortfolioProject..vaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent != '' AND vac.new_vaccinations != ''
)
SELECT *, (VaccinationsUpdate*100)/Population AS VaccinationsRate
FROM VaccinatedPopulation

-- Calculating Vaccination RATE (using CTE) by Nation (without date history)

WITH VaccinatedPopulation (Continent, Location, Population, VaccinationsUpdate)
AS
(
    SELECT dea.continent, dea.location, dea.population,
           SUM(CONVERT(decimal, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationsUpdate
    FROM PortfolioProject..deaths dea
    JOIN PortfolioProject..vaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent != '' AND vac.new_vaccinations != ''
)
SELECT Continent,
		Location,
       MAX(Population) AS Population,
       SUM(VaccinationsUpdate) AS TotalVaccinationsUpdate,
       (MAX(VaccinationsUpdate) * 100) / MAX(Population) AS VaccinationsRate
FROM VaccinatedPopulation
GROUP BY Continent, Location
ORDER BY 1,2;

-- Calculating Vaccination RATE (using CTE) by Continent (without date history)

WITH VaccinatedPopulation (Continent, Location, Population, VaccinationsUpdate)
AS
(
    SELECT dea.continent, dea.location, dea.population,
           SUM(CONVERT(decimal, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationsUpdate
    FROM PortfolioProject..deaths dea
    JOIN PortfolioProject..vaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent != '' AND vac.new_vaccinations != ''
)
SELECT Continent,
       MAX(Population) AS Population,
       SUM(VaccinationsUpdate) AS TotalVaccinationsUpdate,
       (MAX(VaccinationsUpdate) * 100) / MAX(Population) AS VaccinationsRate
FROM VaccinatedPopulation
WHERE Continent IN ('Asia', 'Europe', 'North America', 'South America', 'Oceania', 'Africa')
GROUP BY Continent
ORDER BY 1,2;

-- USE TEMP TABLE for Vaccinations RATE (with Date history)

DROP TABLE IF EXISTS #VaccinatedPercentage
CREATE TABLE #VaccinatedPercentage
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	VaccinationsUpdate numeric
)
INSERT INTO #VaccinatedPercentage
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(decimal, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationsUpdate
FROM PortfolioProject..deaths dea
JOIN PortfolioProject..vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent != '' AND vac.new_vaccinations != ''
SELECT *, (VaccinationsUpdate*100)/Population AS VaccinatedRate
FROM #VaccinatedPercentage

