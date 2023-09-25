
--Checking the data
SELECT *
FROM CovidDeaths


--Selecting the data that is going to be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths)/CONVERT(float, total_cases)*100) AS DeathsPercentage
FROM CovidDeaths
ORDER BY 1,2

--Looking at Total Cases VS Population
SELECT location, date, population, total_cases, (CONVERT(float, total_cases)/CONVERT(float, population)*100) AS PercentageOfPopulationInfected
FROM CovidDeaths
ORDER BY 1,2

--Looking at Maximum Total Cases VS Population For Each Country
SELECT location, population, MAX(total_cases) AS MaximumNumberOfCases, MAX(total_cases)/population*100 AS PercentageOfPopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentageOfPopulationInfected DESC

--Looking at Maximum Deaths For Each Country
SELECT location, MAX(CONVERT(int, total_deaths))
FROM CovidDeaths
GROUP BY location
ORDER BY 2 DESC


--Looking at Maximum Deaths For Each Country
SELECT location, MAX(CONVERT(int, total_deaths)) AS TotalDeathsByContinent 
FROM CovidDeaths
WHERE location IN ('North America', 'South America', 'Asia', 'Europe', 'Africa', 'Oceania') OR (location IS NULL AND continent IS NOT NULL)
GROUP BY location
ORDER BY 2 DESC

--Global Numbers
SELECT SUM(new_cases) AS TotalNewCases, SUM(new_deaths) AS TotalNewDeaths, 
CASE WHEN SUM(new_cases) = 0 
	THEN 0 
	ELSE SUM(new_deaths)/SUM(new_cases) * 100 END
	AS NewDeathsToNewCasesPercentage
FROM CovidDeaths
WHERE location IN ('North America', 'South America', 'Asia', 'Europe', 'Africa', 'Oceania') OR
(location IS NULL AND continent IS NOT NULL)
--GROUP BY date
--ORDER BY 1,2 DESC

--Checking the data from the vaccination table
SELECT *
FROM CovidVac

--Joining the tables
SELECT *
FROM CovidDeaths AS dea
JOIN CovidVac AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date

--Getting Total Population VS New Vaccination 
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations AS NewVaccinationsPerDay
FROM CovidDeaths AS dea
JOIN CovidVac AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY CAST(vac.new_vaccinations as int)

--Getting Rolling Vaccinated people	numbers
SELECT dea.location, dea.date, dea.population, CAST(vac.new_vaccinations as bigint) NewVaccinationsPerDay,
SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM CovidDeaths AS dea
JOIN CovidVac AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2

--View For Rolling people vaccinated
CREATE VIEW PercentPeopleVac AS (
SELECT dea.location, dea.date, dea.population, CAST(vac.new_vaccinations as bigint) NewVaccinationsPerDay,
SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM CovidDeaths AS dea
JOIN CovidVac AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

--Perentage of vaccinated people to the population
WITH VacPeople AS (SELECT CovidVac.location, MAX(CONVERT(bigint, people_fully_vaccinated)) AS VaccinatedPeople
FROM CovidVac
GROUP BY CovidVac.location
)

SELECT CovidVac.location, CovidDeaths.population,VacPeople.VaccinatedPeople, (VacPeople.VaccinatedPeople/CovidDeaths.population) * 100 AS PercentageOfPopulationVaccinated
FROM CovidVac
JOIN VacPeople ON VacPeople.location = CovidVac.location
JOIN CovidDeaths ON CovidDeaths.location = CovidVac.location 
GROUP BY CovidVac.location, CovidDeaths.population, VacPeople.VaccinatedPeople
ORDER BY 1

--Same as above but with a temporary table
DROP TABLE IF EXISTS #VacPeople
CREATE TABLE #VacPeople(
location nvarchar(255),
people_fully_vaccinated bigint
)

INSERT INTO #VacPeople 
SELECT CovidVac.location, MAX(CONVERT(bigint, people_fully_vaccinated))
FROM CovidVac
GROUP BY CovidVac.location

SELECT CovidVac.location, CovidDeaths.population,#VacPeople.people_fully_vaccinated, (#VacPeople.people_fully_vaccinated/CovidDeaths.population) * 100 AS PercentageOfPopulationVaccinated
FROM CovidVac
JOIN #VacPeople ON #VacPeople.location = CovidVac.location
JOIN CovidDeaths ON CovidDeaths.location = CovidVac.location 
GROUP BY CovidVac.location, CovidDeaths.population, #VacPeople.people_fully_vaccinated
ORDER BY 1

--Total Cases and Percent Infected
SELECT location, population, date, ISNULL(MAX(total_cases),0) AS HighestInfectionCount, ISNULL(MAX(total_cases) / population * 100,0) AS PercentPopulationInfected
FROM CovidDeaths
GROUP BY location, population, date
ORDER BY 5 DESC


