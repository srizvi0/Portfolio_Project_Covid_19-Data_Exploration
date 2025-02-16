/*
Covid 19 Data Exploration
Skills worked with: SQL, CTE, TEMP TABLE, WHERE CLAUSE, AGGREGATE FUNCTIONS, CREATING VIEWS
*/

SELECT * FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 3, 4;

-- Select the data we will be using from CovidDeaths Table

SELECT location, last_updated_date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProject.dbo.CovidDeaths 
ORDER BY 1, 2;

-- Total Cases vs Total Deaths 
-- Shows likely hood of dying if you contract covid in your country

SELECT location, last_updated_date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE total_cases <> 0 
ORDER BY 1, 2;

-- Looking at Total Cases vs Total Deaths In America
-- (Note: total_Cases != 0, as it is in denominator)

SELECT location, last_updated_date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE total_cases <> 0 AND location like '%states%'
ORDER BY 1, 2;

-- Looking at Total Cases vs Population For united States
-- Shows what percentage of population has covid in US

SELECT location, last_updated_date, total_cases, population, ((total_Cases/population)*100) AS Percent_Population_Infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE location in ('United States') ORDER BY 1,2;

-- Looking at Country's with Highest Infection Rate compared to Population

SELECT location, population, MAX (total_Cases) AS Highest_Infection_Count, MAX ((total_cases/population)*100) AS Percent_Population_Infected
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location, population
ORDER BY Percent_Population_Infected DESC;

-- Showing Countries Highest Death Count per Population 
-- Casting total_deaths to INT (i.e Coverts Decimal to Int)

SELECT location, MAX (cast(total_deaths AS int)) AS Total_Death_Count
FROM PortfolioProject.dbo.CovidDeaths 
WHERE (continent) <> 'NULL'
GROUP BY location
ORDER BY Total_Death_Count DESC;

-- *BREAKING THINGS DOWN BY CONTINENT* 

SELECT continent, MAX (cast(total_deaths AS int)) AS Total_Death_Count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent <> 'NULL' 
GROUP BY continent
ORDER BY Total_Death_Count DESC;

-- Showing the continents with Highest Death Count

Select continent, Max (total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent <> 'NULL' 
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global Numbers 

SELECT SUM(new_cases) AS total_cases, SUM (cast (new_deaths as int)) as total_deaths, (SUM (new_deaths)/SUM (new_cases))*100 AS Death_Percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE total_deaths <> 0
GROUP BY last_updated_date ORDER BY 1, 2;


-- Covid Vacinations & Covid Deaths Tables

SELECT * FROM PortfolioProject.dbo.CovidVacinations;
SELECT * FROM PortfolioProject.dbo.CovidDeaths;

-- Covid Deaths & Covid Vacinations by iso_code (WHERE Clause)
-- ALIAS CV = COVID VACINATIONS
-- ALIAS CD = COVID DEATHS

SELECT * FROM PortfolioProject.dbo.CovidVacinations CV, PortfolioProject.dbo.CovidDeaths CD 
WHERE CV.iso_code = CD.iso_code;

-- Join Covid Deaths & Covid Vacinations (JOIN Statement) wiht location & date
-- Syntax: SELECT * FROM Table_1 JOIN Table_2 ON Table_1.location = Table_2.location

SELECT * FROM PortfolioProject.dbo.CovidVacinations CV
JOIN PortfolioProject.dbo.CovidDeaths CD
ON CD.location=CV.location AND CD.last_updated_date=CV.last_updated_date;

-- Total Population vs Vacinations
-- Shows Percentage of Population that has recieved at least one Covid vaccine

SELECT CD.continent, CD.location, CD.last_updated_date , CD.population, CV.total_vaccinations
FROM PortfolioProject.dbo.CovidDeaths CD
JOIN PortfolioProject.dbo.CovidVacinations CV
ON CV.location = CD.location AND CV.last_updated_date = CD.last_updated_date
WHERE CD.continent <> 'NULL' 
ORDER BY CD.population;

-- Rolling Sum of Covid New Vacinations by location & date (PARTITION BY CLAUSE)
-- Partition By Used in Analytical functions to devide result set into partitions & apply aggregate function on each partition seperately
-- SYNTAX:
/*
SELECT 
    employee_id,
    department_id,
    salary,
    SUM(salary) OVER(PARTITION BY department_id ORDER BY employee_id) AS running_total
FROM employees;
*/

SELECT CD.continent, CD.location, CD.last_updated_date, CD.population, CV.new_vaccinations,
SUM (CAST(CV.new_vaccinations as INT)) OVER (Partition BY CD.location ORDER BY CD.location, CD.last_updated_date)
AS RollingPeopleVacinated
FROM PortfolioProject.dbo.CovidDeaths CD
JOIN PortfolioProject.dbo.CovidVacinations CV
ON CV.location = CD.location AND CV.last_updated_date = CD.last_updated_date
WHERE CD.continent <> 'NULL' ORDER BY CD.population;

-- USE CTE (Common Table Expression) to perform Calculation on PARTITION BY (RollingPeopleVacinated) in previous query
-- CTE is temporary result set that you can reference within SQL Query
-- SYNTAX:

/*
WITH cte_name (column1, column2, ...)
AS (
    //SQL query defining the CTE
    SELECT column1, column2, ...
    FROM table_name
    WHERE conditions
)
//Using the CTE in a main query
SELECT * FROM cte_name;
*/

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVacinated)
as
(
SELECT CD.continent, CD.location, CD.last_updated_date, CD.population, CV.new_vaccinations,
SUM (CAST(CV.new_vaccinations as INT)) OVER (Partition BY CD.location ORDER BY CD.location, CD.last_updated_date)
AS RollingPeopleVacinated
FROM PortfolioProject.dbo.CovidDeaths CD
JOIN PortfolioProject.dbo.CovidVacinations CV
ON CV.location = CD.location AND CV.last_updated_date = CD.last_updated_date
WHERE CD.continent <> 'NULL'
)
Select *, (RollingPeopleVacinated/Population)*100 FROM PopvsVac;

-- Using Temperary Table to perform Calculation on PARTITION BY in previous query 

DROP TABLE IF EXISTS PERCENTPOPULATIONVACINATED;

CREATE TABLE PERCENTPOPULATIONVACINATED
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into PERCENTPOPULATIONVACINATED
SELECT CD.continent, CD.location, CD.last_updated_date, CD.population, CV.new_vaccinations,
SUM (CAST (CV.new_vaccinations as INT)) OVER (Partition BY CD.location ORDER BY CD.location, CD.last_updated_date) AS RollingPeopleVacinated
FROM PortfolioProject.dbo.CovidDeaths CD
JOIN PortfolioProject.dbo.CovidVacinations CV
ON CV.location = CD.location AND CV.last_updated_date = CD.last_updated_date
WHERE CD.continent <> 'NULL'

SELECT * FROM PERCENTPOPULATIONVACINATED


-- Creating View to store data for later visualizations
-- View is Virtaul table based on result set of SELECT query

-- SYNTAX:

/*
CREATE VIEW view_name AS
SELECT column1, column2, ...
FROM table_name
WHERE conditions;

*/

CREATE VIEW PERCENTPOPULATION_VACINATED AS 
SELECT * FROM PortfolioProject.dbo.CovidDeaths;
