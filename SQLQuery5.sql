select * 
	from Portfolio_Project..CovidDeaths$
	order by 3,4

-- SELECT DATA THAT WE ARE GOING TO USE

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project..CovidDeaths$
ORDER BY 1, 2

-- looking at Total Cases vs Total Deaths
-- shows probability of Death if contract covid in given country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM Portfolio_Project..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1, 2

-- Total cases v population
--Shows what % of population got Covid

SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentageInfected
FROM Portfolio_Project..CovidDeaths$
WHERE location = 'United Kingdom'
ORDER BY 1, 2

-- Looking at country with highest infection rate

SELECT location, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentageInfected
FROM Portfolio_Project..CovidDeaths$
Group by location, population
ORDER BY PercentageInfected DESC

-- show countries with highest death count/population

SELECT location, MAX(cast(total_deaths as INT)) as HighestDeathCount
FROM Portfolio_Project..CovidDeaths$
WHERE continent is not null
Group by location
ORDER BY HighestDeathCount DESC

-- breakdown by Continent

SELECT location, MAX(cast(total_deaths as INT)) as HighestDeathCount
FROM Portfolio_Project..CovidDeaths$
-- where location is continent in data set, continent is null
WHERE continent is null
Group by location
ORDER BY HighestDeathCount DESC

-- Global numbers

SELECT sum(new_cases)as total_cases, 
	sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as Int))/sum(new_cases)*100 as deathpercentage
From Portfolio_Project..CovidDeaths$
Where continent is not null
-- group by date
order by 1,2

--country avg. reproduction and %death

Select location, avg(cast(reproduction_rate as Float)) as Avg_Reproduction, sum(cast(new_deaths as Int))/sum(new_cases)*100 AS DEATHPERCENTAGE
From Portfolio_Project..CovidDeaths$
group by location
Order by 2 DESC--looking at total Pop v Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	sum(cast(vac.new_vaccinations as Int)) over (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
from Portfolio_Project..CovidVaccinations$ vac
Join Portfolio_Project..CovidDeaths$ dea
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- USE CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	sum(cast(vac.new_vaccinations as Int)) over (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
from Portfolio_Project..CovidVaccinations$ vac
Join Portfolio_Project..CovidDeaths$ dea
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2, 3
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentPopVaccinated
From PopvsVac

-- TEMP TABLE
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, 
dea.population, vac.new_vaccinations, 
	sum(convert(bigint,vac.new_vaccinations)) 
	over (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
from Portfolio_Project..CovidVaccinations$ vac
Join Portfolio_Project..CovidDeaths$ dea
	on vac.location = dea.location
	and vac.date = dea.date


Select *, (RollingPeopleVaccinated/Population)*100 as PercentVaccinated
From  #PercentPopulationVaccinated
where Continent is not null
order by 2,3

-- Total Deathcount by Continent

SELECT continent, MAX(cast(total_deaths as INT)) as TotalDeathCount
FROM Portfolio_Project..CovidDeaths$
WHERE continent is not null
Group by continent
ORDER BY TotalDeathCount DESC

-- Creating view to store data for later visualizations
drop view if exists PercentPopulationVaccinated
Create View PercentPopulationVaccinated as 
select dea.continent, dea.location, dea.date, 
dea.population, vac.new_vaccinations, 
	sum(convert(bigint,vac.new_vaccinations)) 
	over (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
from Portfolio_Project..CovidVaccinations$ vac
Join Portfolio_Project..CovidDeaths$ dea
	on vac.location = dea.location
	and vac.date = dea.date
where dea.continent is not null
 


 select *
 From PercentPopulationVaccinated