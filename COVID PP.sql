/*
COVID-19 Worldwide Vaccination Data Exploration Using SQL

Using - Joins, CTE, Temp Tables, Windows functions, Aggregate functions, creating views, Converting data types
*/

SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

-- 1) What is the Mortality rate - total deaths divided by total cases
SELECT location, date, total_cases, total_deaths, CAST(total_deaths AS float)/(total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE Continent is not NULL 
AND total_deaths IS NOT NULL
ORDER BY 1,2

-- 2) What percentage of the population got covid
-- Shows what percentage of the population got COVID 
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE Continent IS NOT NULL 
AND total_cases IS NOT NULL
ORDER BY 1,2

-- 3) What country has the highest infection rate compaired to population
SELECT location, population, 
	   MAX(CAST(total_cases AS INT)) AS HighestInfectionCount, 
	   MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- 4) What country has the highest death count per population
--Showing countries with highest death count per population
SELECT continent,location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent,location
ORDER BY TotalDeathCount DESC

-- 5) What continent has the highest death count
-- Let's break things down by continent
-- Showing continent with highest death count per population
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL
AND location IN ('Europe','Asia','North America','South America','Africa','Oceania')
GROUP BY location
ORDER BY TotalDeathCount DESC

 --Global Numbers
 -- 6) What are the global cases for each day
SELECT date, SUM(new_cases) AS TotalCases, 
	SUM(new_deaths) AS TotalDeaths,
	(SUM(new_deaths) / NULLIF(SUM(new_cases), 0)*100) AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,4

-- 7) What is the rolling count of people vaccinated, meaning after each day what is the total number of vaccinated people
-- Looking at Total Population VS vaccinations
-- Using CTE
WITH popVSvac(continent, location, date,
	 population, new_vaccinations, RollingCountOfPeopleVaccinated)
AS
(
	SELECT dea.continent, dea.location, dea.date,
	   dea.population, vac.new_vaccinations,
	   SUM(CONVERT(BIGINT, vac.new_vaccinations)) 
	   OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	   AS RollingCountOfPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	 ON dea.location = vac.location
	 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, (RollingCountOfPeopleVaccinated/population)*100 AS PercentageofVaccinatedPeople
FROM popVSvac

-- Using TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date,
	   dea.population, vac.new_vaccinations,
	   SUM(CONVERT(BIGINT, vac.new_vaccinations)) 
	   OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date )
	   AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	 ON dea.location = vac.location
	 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentageofVaccinatedPeople
FROM #PercentPopulationVaccinated


-- Creating views to store our results and later use for data visualization 
--1
CREATE VIEW mortalityrate AS 
SELECT location, date, total_cases, total_deaths, CAST(total_deaths AS float)/(total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE Continent is not NULL 
AND total_deaths IS NOT NULL
ORDER BY 1,2;

--2
CREATE VIEW PercentPopulationInfected AS 
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE Continent IS NOT NULL 
AND total_cases IS NOT NULL
ORDER BY 1,2;

--3
CREATE VIEW HighestInfectedCountry AS 
SELECT location, population, 
	   MAX(CAST(total_cases AS INT)) AS HighestInfectionCount, 
	   MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--4
CREATE VIEW HighestDeathperPopulation AS 
SELECT continent,location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent,location
ORDER BY TotalDeathCount DESC

--5
CREATE VIEW HighestDeathCountContinent AS 
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL
AND location IN ('Europe','Asia','North America','South America','Africa','Oceania')
GROUP BY location
ORDER BY TotalDeathCount DESC

--6
CREATE VIEW GlobalCasesPerDay AS 
SELECT date, SUM(new_cases) AS TotalCases, 
	SUM(new_deaths) AS TotalDeaths,
	(SUM(new_deaths) / NULLIF(SUM(new_cases), 0)*100) AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,4

--7
CREATE VIEW PercentageofVaccinatedPeople AS 
WITH popVSvac(continent, location, date,
	 population, new_vaccinations, RollingCountOfPeopleVaccinated)
AS
(
	SELECT dea.continent, dea.location, dea.date,
	   dea.population, vac.new_vaccinations,
	   SUM(CONVERT(BIGINT, vac.new_vaccinations)) 
	   OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	   AS RollingCountOfPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	 ON dea.location = vac.location
	 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, (RollingCountOfPeopleVaccinated/population)*100 AS PercentageofVaccinatedPeople
FROM popVSvac

