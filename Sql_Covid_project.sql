SELECT *
FROM [SQL portfolios]..CovidDeaths
ORDER BY 3,4

--Selecting the important columns

SELECT location, date, total_cases, total_deaths, population	 
FROM [SQL portfolios]..CovidDeaths
ORDER BY 1,2

--Now let us find the Total cases vs Total deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage	 
FROM [SQL portfolios]..CovidDeaths
WHERE location like '%ind%'
ORDER BY 1,2

--Now we will look at what percentage of the population got covid

SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected	 
FROM [SQL portfolios]..CovidDeaths
WHERE location = 'India'
ORDER BY 1,2

--Looking at countries which got highest infection rate compared to population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected	 	 
FROM [SQL portfolios]..CovidDeaths
--WHERE location = 'India'
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

--Looking at countries with highest death rates perpopulation

SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM [SQL portfolios]..CovidDeaths
--WHERE location = 'India'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


--Looking at continents with highest deaths

SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM [SQL portfolios]..CovidDeaths
--WHERE location = 'India'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc


--Breaking down to total number of cases and deaths on the whole world.

SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as TotalDeathPercentage
FROM [SQL portfolios]..CovidDeaths
--WHERE location = 'India'
WHERE continent is not null
--GROUP BY date
ORDER BY 1

--Now we have to join the covid_vaccination table with this table.

SELECT *
FROM [SQL portfolios]..CovidDeaths dea
JOIN [SQL portfolios]..CovidVaccinations vac
	ON dea.date = vac.date
	and dea.location = vac.location


--Total population vs vaccination 

-- We are using rollingcount method to find the sum of vaccinations of each country.
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100 as PercentPopulationVaccinated 
--!!! SINCE THE COLUMN IS JUST CREATED YOU CANNOT RUN THIS
FROM [SQL portfolios]..CovidDeaths dea
JOIN [SQL portfolios]..CovidVaccinations vac
	ON dea.date = vac.date
	and dea.location = vac.location
WHERE dea.continent is not null
ORDER BY 2,3


--We have to use a CTE to find the total population vs vaccination.

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
FROM [SQL portfolios]..CovidDeaths dea
JOIN [SQL portfolios]..CovidVaccinations vac
	ON dea.date = vac.date
	and dea.location = vac.location
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100 as PercentPopulationVaccinated
FROM PopvsVac


--Now we'll try this same with a TEMP table.

DROP TABLE IF exists #PercentPopulationVaccinated
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
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
FROM [SQL portfolios]..CovidDeaths dea
JOIN [SQL portfolios]..CovidVaccinations vac
	ON dea.date = vac.date
	and dea.location = vac.location
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100 as PercentPopulationVaccinated
FROM #PercentPopulationVaccinated

--Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated
as
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) as RollingPeopleVaccinated
FROM [SQL portfolios]..CovidDeaths dea
JOIN [SQL portfolios]..CovidVaccinations vac
	ON dea.date = vac.date
	and dea.location = vac.location
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100 as PercentPopulationVaccinated
FROM PopvsVac


