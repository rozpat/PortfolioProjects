SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT * 
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths in United Kingdom
-- Likelihood of dying 
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Kingdom%'
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths (in Poland and United Kingdom)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location = 'Poland' OR location LIKE '%Kingdom%'
ORDER BY 1,2

-- Looking at Total Cases vs Population in Poland and United Kingdom
-- Percentage of the popultion that got covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
-- WHERE location = 'Poland' OR location LIKE '%Kingdom%'
ORDER BY 1,2

-- Looking at countries with Highest Infection Rate compared to population 
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
-- WHERE location = 'Poland' OR location LIKE '%Kingdom%'
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

-- Looking at countries with Highest Death Count compared to population 
SELECT location, population, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
-- WHERE location = 'Poland' OR location LIKE '%Kingdom%'
GROUP BY location, population
ORDER BY TotalDeathCount desc

-- Looking at countries with Highest Death Rate compared to population 
SELECT location, population, MAX(CAST(total_deaths AS int)) AS TotalDeathCount, MAX((total_deaths/population))*100 AS PercentPopulationDead
FROM PortfolioProject..CovidDeaths
-- WHERE location = 'Poland' OR location LIKE '%Kingdom%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationDead desc

-- BREAK DOWN BY CONTINENTS

-- Continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location != 'World'
GROUP BY location
ORDER BY TotalDeathCount desc

-- GLOBAL NUMBERS 

SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location LIKE '%Kingdom%'
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2

-- JOIN TABLES

SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

-- Rolling People Vaccinated per country
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Rolling People Vaccinated in Poland and UK
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.location = 'Poland' OR dea.location LIKE '%Kingdom%'
ORDER BY 2,3

-- Total number of people vaccinated in the UK and Poland (or whole world)
SELECT continent, location, SUM(CAST(new_vaccinations AS INT)) AS TotalPeopleVaccinated
FROM PortfolioProject..CovidVaccinations
WHERE location LIKE '%Kingdom%' OR location = 'Poland' OR location LIKE '%Gib%'
--WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY TotalPeopleVaccinated desc

-- Percentage of all population being vaccinated 

-- Whole world
-- Use CTE
-- Get rid of NULL values
WITH PopVsVac (Continent, Location, Date, Population, NewVaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, COALESCE(dea.population, 0), COALESCE(vac.new_vaccinations, 0)
, COALESCE(SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date), 0) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, ISNULL((RollingPeopleVaccinated/NULLIF(Population, 0)), 0)*100 AS VaccinationPercentage
FROM PopVsVac


-- Total people vaccinated across all countries and vaccination rate 
-- Get rid of NULL values
WITH PopVsVac2 (Continent, Location, Date, Population, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, COALESCE(dea.population, 0) AS Population
, COALESCE(SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date), 0) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT Continent, Location, Population, MAX(RollingPeopleVaccinated) AS TotalPeopleVaccinated, ISNULL(MAX(RollingPeopleVaccinated)/NULLIF(Population, 0), 0)*100 AS VaccinationPercentage
FROM PopVsVac2
-- WHERE location = 'Poland' OR location LIKE '%Kingdom%'
GROUP BY Continent, Location, Population
ORDER BY VaccinationPercentage desc


-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
-- WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100 AS VaccinationPercentage
FROM #PercentPopulationVaccinated


-- Create views to store data for the visualisations

CREATE VIEW PercentPopulationVaccinatedRolling AS
SELECT dea.continent, dea.location, dea.date, COALESCE(dea.population, 0) AS Population, COALESCE(vac.new_vaccinations, 0) AS NewVaccinations
, COALESCE(SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date), 0) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


USE PortfolioProject
GO
CREATE VIEW PercentPopulationVaccinatedTotal AS
WITH PopVsVac2 (Continent, Location, Date, Population, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, COALESCE(dea.population, 0) AS Population
, COALESCE(SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date), 0) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT Continent, Location, Population, MAX(RollingPeopleVaccinated) AS TotalPeopleVaccinated, ISNULL(MAX(RollingPeopleVaccinated)/NULLIF(Population, 0), 0)*100 AS VaccinationPercentage
FROM PopVsVac2
-- WHERE location = 'Poland' OR location LIKE '%Kingdom%'
GROUP BY Continent, Location, Population


CREATE VIEW GlobalDeathPercentage AS  
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL


CREATE VIEW PopulationInfectiousRatePerCountry AS
SELECT Location, COALESCE(population, 0) AS Population, COALESCE(MAX(total_cases), 0) AS HighestInfectionCount
,  ISNULL(MAX((total_cases/NULLIF(population, 0))), 0)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population


USE PortfolioProject
GO
CREATE VIEW PopulationInfectiousRatePerDay AS
SELECT Location, COALESCE(population, 0) AS Population, Date, COALESCE(MAX(total_cases), 0) AS HighestInfectionCount
,  ISNULL(MAX((total_cases/NULLIF(population, 0))), 0)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population, date


USE PortfolioProject
GO
CREATE VIEW TotalDeathsPerContinent AS
SELECT location, SUM(CAST(new_deaths AS INT)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null 
AND LOCATION NOT IN ('World', 'European Union', 'International')
GROUP BY location

SELECT *
FROM PercentPopulationVaccinatedTotal
