/* =========================================================
   NOEMIE TOUITOU 348383258
   =========================================================
   PROJECT 1 : Global CO2 Emissions and Energy Analysis
   =========================================================

   In this project, I chose to work on global environmental
   indicators with a focus on CO2 emissions and energy usage
   across different countries and years.

   The objective of this database is to provide a clean and
   well-structured data model that can later be used for
   advanced analysis in BI tools such as Power BI and Python.

   Particular attention was given to:
   - Proper relational design and normalization
   - Ensuring data integrity using constraints
   - Building a structure compatible with analytical models
     (star-schema friendly)
   - Using precise data types (DECIMAL instead of FLOAT)
     to guarantee reliable numerical analysis

   This database is not only designed to store data, but
   to be used for real analytical purposes on large datasets.

   ========================================================= */

/* =========================================================
   1. CREATE DATABASE
   ========================================================= */

CREATE DATABASE ClimateImpactDB;
GO

USE ClimateImpactDB;
GO


/* =========================================================
   TABLE: Countries (Dimension Table)

   Stores descriptive information about each country.
   This table is referenced by fact tables (Emissions,
   EnergyConsumption) using the ISO code as a unique key.
   ========================================================= */

CREATE TABLE Countries (
    country_id INT IDENTITY(1,1) PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL, 
    iso_code CHAR(3) UNIQUE NOT NULL,
    continent VARCHAR(50) NOT NULL,
    region VARCHAR(100),
    population BIGINT CHECK (population >= 0),
    area_km2 DECIMAL(12,2) CHECK (area_km2 > 0),
    gdp_usd DECIMAL(18,2) CHECK (gdp_usd >= 0),
    created_at DATETIME DEFAULT GETDATE()
);


/* =========================================================
   TABLE: Years (Time Dimension)

   Represents the time dimension of the database.
   Separating time improves normalization and enables
   easier temporal analysis in BI tools.
   ========================================================= */

CREATE TABLE Years (
    year_id INT IDENTITY(1,1) PRIMARY KEY,
    year INT UNIQUE NOT NULL CHECK (year >= 1900),
    decade INT,
    global_temperature_anomaly DECIMAL(5,2)
);

/* =========================================================
   TABLE: EnergySources (Dimension Table)

   Contains the list of energy types categorized into
   fossil, renewable, and low-carbon sources.
   Used to analyze the environmental impact of
   different energy sources.
   ========================================================= */

CREATE TABLE EnergySources (
    energy_id INT IDENTITY(1,1) PRIMARY KEY,
    energy_name VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(50) NOT NULL,
    co2_factor DECIMAL(5,2) CHECK (co2_factor >= 0),
    description VARCHAR(255)
);


/* =========================================================
   TABLE: Emissions (Fact Table)

   Stores yearly CO2 and greenhouse gas indicators
   for each country.
   A unique constraint ensures one record per
   country and year to preserve data integrity.
   ========================================================= */

CREATE TABLE Emissions (
    emission_id INT IDENTITY(1,1) PRIMARY KEY,
    country_id INT NOT NULL,
    year_id INT NOT NULL,
    total_co2 DECIMAL(12,2) CHECK (total_co2 >= 0),
    co2_per_capita DECIMAL(10,2) CHECK (co2_per_capita >= 0),
    methane DECIMAL(10,2) CHECK (methane >= 0),
    nitrous_oxide DECIMAL(10,2) CHECK (nitrous_oxide >= 0),
    co2_growth_rate DECIMAL(6,2),
    cumulative_co2 DECIMAL(15,2) CHECK (cumulative_co2 >= 0),
    last_updated DATETIME DEFAULT GETDATE(),

    CONSTRAINT UQ_Emission UNIQUE (country_id, year_id),

    FOREIGN KEY (country_id) REFERENCES Countries(country_id),
    FOREIGN KEY (year_id) REFERENCES Years(year_id)
);


/* =========================================================
   TABLE: EnergyConsumption (Fact Table)

   Records yearly energy consumption by country
   and energy source.
   Prevents duplicate entries using a unique
   constraint on country, year, and energy type.
   ========================================================= */

CREATE TABLE EnergyConsumption (
    consumption_id INT IDENTITY(1,1) PRIMARY KEY,
    country_id INT NOT NULL,
    year_id INT NOT NULL,
    energy_id INT NOT NULL,

    energy_consumption_twh DECIMAL(12,2) CHECK (energy_consumption_twh >= 0),
    share_of_total_energy DECIMAL(5,2) CHECK (share_of_total_energy >= 0),
    electricity_generation DECIMAL(12,2) CHECK (electricity_generation >= 0),
    renewable_share DECIMAL(5,2) CHECK (renewable_share >= 0),
    efficiency_index DECIMAL(5,2) CHECK (efficiency_index >= 0),

    CONSTRAINT UQ_Energy UNIQUE (country_id, year_id, energy_id),

    FOREIGN KEY (country_id) REFERENCES Countries(country_id),
    FOREIGN KEY (year_id) REFERENCES Years(year_id),
    FOREIGN KEY (energy_id) REFERENCES EnergySources(energy_id)
);



/* =========================================================
   DATA IMPORT FROM OWID DATASETS

   Raw datasets from Our World in Data were first
   imported into staging tables.

   Data was then transformed and inserted into the
   normalized schema using INSERT-SELECT statements.

   Dataset : CO₂ and Greenhouse Gas Emissions
   ourworldindata.org/co2-and-greenhouse-gas-emissions
   - Our World in Data CO2 dataset csv
   - Our World in Data Energy dataset csv

   using Microsoft.SqlServer.Import.Wizard
   ========================================================= */

    select * from Staging_CO2_Raw
    select * from Staging_Energy_Raw


    /* Populate the Years table from raw data.
   Also computes the decade and average
   global temperature anomaly per year. */
    INSERT INTO Years (year, decade, global_temperature_anomaly)
    SELECT 
        year,
        (year/10)*10,
        AVG(TRY_CAST(temperature_change_from_ghg AS DECIMAL(5,2))) AS global_temperature_anomaly
    FROM Staging_CO2_Raw
    WHERE year >= 1900
    GROUP BY year;


    /* Populate the Countries table using ISO codes.
   Population and GDP are aggregated from
   the most recent available values. */
    INSERT INTO Countries (country_name, iso_code, continent, population, gdp_usd)
    SELECT
        country,
        iso_code,
        'Unknown',
        MAX(TRY_CAST(population AS BIGINT)),
        MAX(TRY_CAST(gdp AS DECIMAL(18,2)))
    FROM Staging_CO2_Raw
    WHERE iso_code IS NOT NULL
    GROUP BY country, iso_code;

    /* Insert predefined energy sources with their
   environmental category and CO2 emission factor. */
    INSERT INTO EnergySources (energy_name, category, co2_factor)
    VALUES
    ('Coal', 'Fossil', 3.8),
    ('Oil', 'Fossil', 3.1),
    ('Gas', 'Fossil', 2.4),
    ('Nuclear', 'Low Carbon', 0.1),
    ('Hydro', 'Renewable', 0.05),
    ('Solar', 'Renewable', 0.02),
    ('Wind', 'Renewable', 0.01);


    /* Insert emissions indicators by joining
   staging data with Countries and Years.
   TRY_CAST is used to ensure data quality
   and prevent import errors. */
    INSERT INTO Emissions (
        country_id,
        year_id,
        total_co2,
        co2_per_capita,
        methane,
        nitrous_oxide,
        co2_growth_rate,
        cumulative_co2
    )
    SELECT
        c.country_id,
        y.year_id,
        TRY_CAST(s.co2 AS DECIMAL(12,2)),
        TRY_CAST(s.co2_per_capita AS DECIMAL(10,2)),
        TRY_CAST(s.methane AS DECIMAL(10,2)),
        TRY_CAST(s.nitrous_oxide AS DECIMAL(10,2)),
        TRY_CAST(s.co2_growth_prct AS DECIMAL(6,2)),
        TRY_CAST(s.cumulative_co2 AS DECIMAL(15,2))
    FROM Staging_CO2_Raw s
    JOIN Countries c ON s.iso_code = c.iso_code
    JOIN Years y ON s.year = y.year
    WHERE s.co2 IS NOT NULL;





    /* Insert energy consumption data for all specific
   energy source (by joining staging data with
   Countries and Years tables) -- 7 times. */
    INSERT INTO EnergyConsumption
    (country_id, year_id, energy_id,
     energy_consumption_twh, electricity_generation, share_of_total_energy)
    SELECT
        c.country_id,
        y.year_id,
        1,  --coal
        s.coal_consumption,
        s.electricity_generation,
        s.fossil_share_energy
    FROM Staging_Energy_Raw s
    JOIN Countries c ON s.iso_code = c.iso_code
    JOIN Years y ON s.year = y.year
    WHERE s.coal_consumption IS NOT NULL;


    INSERT INTO EnergyConsumption
    (country_id, year_id, energy_id,
     energy_consumption_twh, electricity_generation, share_of_total_energy)
    SELECT
        c.country_id,
        y.year_id,
        2,   --oil
        s.oil_consumption,
        s.electricity_generation,
        s.fossil_share_energy
    FROM Staging_Energy_Raw s
    JOIN Countries c ON s.iso_code = c.iso_code
    JOIN Years y ON s.year = y.year
    WHERE s.oil_consumption IS NOT NULL;


    INSERT INTO EnergyConsumption
    (country_id, year_id, energy_id,
     energy_consumption_twh, electricity_generation, share_of_total_energy)
    SELECT
        c.country_id,
        y.year_id,
        3,    --gas
        s.gas_consumption,
        s.electricity_generation,
        s.fossil_share_energy
    FROM Staging_Energy_Raw s
    JOIN Countries c ON s.iso_code = c.iso_code
    JOIN Years y ON s.year = y.year
    WHERE s.gas_consumption IS NOT NULL;


    INSERT INTO EnergyConsumption
    (country_id, year_id, energy_id,
     energy_consumption_twh, electricity_generation, share_of_total_energy)
    SELECT
        c.country_id,
        y.year_id,
        4,   -- nuclear
        s.nuclear_consumption,
        s.electricity_generation,
        s.renewables_share_energy
    FROM Staging_Energy_Raw s
    JOIN Countries c ON s.iso_code = c.iso_code
    JOIN Years y ON s.year = y.year
    WHERE s.nuclear_consumption IS NOT NULL;


    INSERT INTO EnergyConsumption
    (country_id, year_id, energy_id,
     energy_consumption_twh, electricity_generation, share_of_total_energy)
    SELECT
        c.country_id,
        y.year_id,
        5,    --hydro
        s.hydro_consumption,
        s.electricity_generation,
        s.renewables_share_energy
    FROM Staging_Energy_Raw s
    JOIN Countries c ON s.iso_code = c.iso_code
    JOIN Years y ON s.year = y.year
    WHERE s.hydro_consumption IS NOT NULL;


    INSERT INTO EnergyConsumption
    (country_id, year_id, energy_id,
     energy_consumption_twh, electricity_generation, share_of_total_energy)
    SELECT
        c.country_id,
        y.year_id,
        6,   --solar
        s.solar_consumption,
        s.electricity_generation,
        s.renewables_share_energy
    FROM Staging_Energy_Raw s
    JOIN Countries c ON s.iso_code = c.iso_code
    JOIN Years y ON s.year = y.year
    WHERE s.solar_consumption IS NOT NULL;


    INSERT INTO EnergyConsumption
    (country_id, year_id, energy_id,
     energy_consumption_twh, electricity_generation, share_of_total_energy)
    SELECT
        c.country_id,
        y.year_id,
        7,   --wind
        s.wind_consumption,
        s.electricity_generation,
        s.renewables_share_energy
    FROM Staging_Energy_Raw s
    JOIN Countries c ON s.iso_code = c.iso_code
    JOIN Years y ON s.year = y.year
    WHERE s.wind_consumption IS NOT NULL;




    -- END OF DATABASE CREATION :)
