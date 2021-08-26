SELECT * FROM PortfolioProject..CovidDeaths
ORDER BY 3,4


SELECT * FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4

-- Required data to work with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Total cases vs Total deaths in Poland and Iran
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location IN ('Poland','Iran')
ORDER BY 1,2

-- Total cases vs population in Poland and Iran
SELECT location, date, total_cases, population, (total_cases/population)*100 CovidPopulationPercentage
FROM PortfolioProject..CovidDeaths
WHERE location IN ('Poland','Iran')
ORDER BY 1,2

-- Highest infection rate based on poplulation
SELECT location, 
	MAX(total_cases) HighestInfectionCount, 
	population, 
	MAX((total_cases/population))*100 MaxPopulationPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY MaxPopulationPercentage DESC

-- Highest death rate based on population
SELECT location,
	MAX(CAST(total_deaths AS int)) HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE location NOT IN ('World','Europe', 'South America','Asia','North America','European Union','Africa','South Africa','Oceania')
GROUP BY location
ORDER BY HighestDeathCount DESC

-- Or we can filter based on not-null continent
SELECT location,
	MAX(CAST(total_deaths AS int)) HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathCount DESC


SELECT location,
	MAX(CAST(total_deaths AS int)) HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY HighestDeathCount DESC

-- Continents with high death based on population
SELECT continent,
	MAX(CAST(total_deaths AS int)) HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC

-- The top three days for global death counts all happened in January 2021
SELECT
	date, 
	SUM(new_cases) TotalNewCases, 
	SUM(CAST(new_deaths AS int)) TotalNewDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 3 DESC

-- Overal death percentage per cases
SELECT
	SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY DeathPercentage DESC


-- Total population who recieved vaccination
SELECT d.continent, 
	d.location, 
	d.date, population, 
	v.new_vaccinations 
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
	ON d.location = v.location 
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3

-- When was the first day Poland started the vaccination and how many vaccinated
SELECT TOP(1) d.date, 
	v.new_vaccinations 
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
	ON d.location = v.location 
	AND d.date = v.date
WHERE d.continent IS NOT NULL
AND d.location = 'Poland' AND v.new_vaccinations IS NOT NULL
ORDER BY d.date

-- Running total based on countries
SELECT d.continent,
	d.location,
	d.date,
	population,
	v.new_vaccinations,
	SUM(CONVERT(int,v.new_vaccinations)) 
OVER (PARTITION BY d.location ORDER BY d.date) RunningTotal
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL --AND v.new_vaccinations IS NOT NULL
ORDER BY 2,3

-- Using CTE for further analysis
WITH PopVacc (Continent, Location, Date, Population, New_Vaccination, RunningTotal)
AS (SELECT d.continent,
	d.location,
	d.date,
	population,
	v.new_vaccinations,
	SUM(CONVERT(int,v.new_vaccinations)) 
OVER (PARTITION BY d.location ORDER BY d.date) RunningTotal
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
)
SELECT *,
	(RunningTotal/Population)*100 RollingPercVacc
FROM PopVacc

-- Now with temp table
DROP TABLE IF EXISTS #PercentPeopleVaccinated
CREATE TABLE #PercentPeopleVaccinated (
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RunningTotal numeric)
INSERT INTO #PercentPeopleVaccinated 
SELECT d.continent,
	d.location,
	d.date,
	population,
	v.new_vaccinations,
	SUM(CONVERT(int,v.new_vaccinations)) 
OVER (PARTITION BY d.location ORDER BY d.date) RunningTotal
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *,
	(RunningTotal/Population)*100 RollingPercVacc
FROM #PercentPeopleVaccinated


-- Creating a view
CREATE VIEW PercentPeopleVaccinated AS
SELECT d.continent,
	d.location,
	d.date,
	population,
	v.new_vaccinations,
	SUM(CONVERT(int,v.new_vaccinations)) 
OVER (PARTITION BY d.location ORDER BY d.date) RunningTotal
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT * FROM PercentPeopleVaccinated