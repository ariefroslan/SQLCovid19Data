/* 

COVID 19 DATA EXPLORATION
Data Source: https://ourworldindata.org/covid-deaths

Skills Used Including: Alter Table, Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions,
Creating Views, Convert Data Types

 */


SELECT *
FROM CovidDataProject..CovDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM CovidDataProject..CovVaxx
--ORDER BY 3,4

SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'CovDeaths' AND
    COLUMN_NAME IN ('total_cases', 'total_deaths')


--Select Data That Are Going To Be Used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDataProject..CovDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



--Alter Table to do Calculation
ALTER TABLE CovDeaths
ALTER COLUMN total_cases INT

ALTER TABLE CovDeaths
ALTER COLUMN total_deaths INT



-- Looking at Total Deaths vs Total Cases
-- The likelihood of dying from Covid-19 in Malaysia
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS decimal)/CAST(total_cases AS decimal))*100 as DeathPercentage
FROM CovidDataProject..CovDeaths
WHERE location like '%malaysia%'
ORDER BY 1,2



-- Looking at the total cases vs population
SELECT location, date, total_cases, population, (CAST(total_cases AS decimal)/CAST(population AS decimal))*100 as CasesPercentageOfPopulation
FROM CovidDataProject..CovDeaths
WHERE location like '%malaysia%' and continent IS NOT NULL
ORDER BY 1,2



-- Looking at the total deaths vs population
SELECT location, date, total_deaths, population, (CAST(total_deaths AS decimal)/CAST(population AS decimal))*100 as DeathsPercentageOfPopulation
FROM CovidDataProject..CovDeaths
WHERE location like '%malaysia%'
ORDER BY 1,2



--What country has the highest infection rate compared to its population
SELECT location, population, MAX(total_cases) as HighestInfectionRate, MAX(CAST(total_cases AS DECIMAL)/CAST(population AS DECIMAL))*100 as PercentPopulationInfected
FROM CovidDataProject..CovDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected

SELECT location, population, MAX(total_cases) as HighestInfectionRate, MAX(CAST(total_cases AS DECIMAL)/CAST(population AS DECIMAL))*100 as PercentPopulationInfected
FROM CovidDataProject..CovDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected desc



--Looking at countries with highest death rate
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM CovidDataProject..CovDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount desc



--Showing the continent with the highest death rate
--Sorting the death rate by continent
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM CovidDataProject..CovDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

SELECT location, MAX(total_deaths) as TotalDeathCount
FROM CovidDataProject..CovDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount desc



--Looking at total cases & death worlwide as at 31/5/2023
SELECT SUM(CAST(new_deaths AS INT)) as TotalDeathWorldwide
FROM CovidDataProject..CovDeaths
WHERE continent IS NOT NULL

SELECT date, SUM(new_cases) as TodayTotalCasesWorldwide
FROM CovidDataProject..CovDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

SELECT date, SUM(CAST(new_deaths AS INT)) as TodayTotalDeathsWorldwide
FROM CovidDataProject..CovDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


SELECT *
FROM CovidDataProject..CovVaxx
ORDER BY 1,2



--Joining 2 tables together
SELECT * 
FROM CovidDataProject..CovDeaths dea
JOIN CovidDataProject..CovVaxx vac
	On dea.location = vac.location
	and dea.date = vac.date


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
FROM CovidDataProject..CovDeaths dea
JOIN CovidDataProject..CovVaxx vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3



--Looking at new vaccination by country on daily basis
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as NumberOfPeopleVaccinated
FROM CovidDataProject..CovDeaths dea
JOIN CovidDataProject..CovVaxx vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3



--Using CTE
WITH VaxVsPopulation (continent, location, date, population, new_vaccinations, NumberOfPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as NumberOfPeopleVaccinated
FROM CovidDataProject..CovDeaths dea
JOIN CovidDataProject..CovVaxx vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (NumberOfPeopleVaccinated/Population)*100 as PercetageOfVaccinated
    FROM VaxVsPopulation
    ORDER BY 2,3



--Looking at Malaysia Case
WITH VaxVsPopulation (continent, location, date, population, new_vaccinations, NumberOfPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as NumberOfPeopleVaccinated
FROM CovidDataProject..CovDeaths dea
JOIN CovidDataProject..CovVaxx vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (NumberOfPeopleVaccinated/Population)*100 as PercetageOfVaccinated
    FROM VaxVsPopulation
    WHERE location like '%malaysia%'
    ORDER BY 2,3



--Temp Table 
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population BIGINT,
    New_Vaccinations INT,
    NumberOfPeopleVaccinated BIGINT
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as NumberOfPeopleVaccinated
FROM CovidDataProject..CovDeaths dea
JOIN CovidDataProject..CovVaxx vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (CAST(NumberOfPeopleVaccinated AS DECIMAL)/Population)*100 as PercetageOfVaccinated
FROM #PercentPopulationVaccinated
ORDER BY 2,3



--Creating view for future data visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as NumberOfPeopleVaccinated
FROM CovidDataProject..CovDeaths dea
JOIN CovidDataProject..CovVaxx vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated
ORDER BY 2,3