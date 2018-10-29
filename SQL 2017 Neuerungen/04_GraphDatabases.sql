
CREATE DATABASE GraphDatabase
GO

USE GraphDatabase
GO

-- Create a staging table for the airports
CREATE TABLE Airports_Staging
(
	AirportID VARCHAR(100),
	Name VARCHAR(100),
	City VARCHAR(100),
	Country VARCHAR(100),
	IATA VARCHAR(100),
	ICAO VARCHAR(100),
	Latitude VARCHAR(100),
	Longitude VARCHAR(100),
	Altitude VARCHAR(100),
	Timezone VARCHAR(100),
	DST VARCHAR(100),
	TzDatabaseTime VARCHAR(100),
	Type VARCHAR(100),
	Source VARCHAR(100)
)
GO

-- Create a staging table for the individual routes
CREATE TABLE Routes_Staging
(
	Airline VARCHAR(100),
	AirlineID VARCHAR(100),
	SourceAirport VARCHAR(100),
	SourceAirportID VARCHAR(100),
	DestinationAirport VARCHAR(100),
	DestinationAirportID VARCHAR(100),
	Codeshare VARCHAR(100),
	[Stop] VARCHAR(100),
	Equipment VARCHAR(100)
)
GO

-- Insert the airports into the staging table
BULK INSERT Airports_Staging
FROM 'C:\Users\Boss\Desktop\DEMOS\Neuerungen 2017\Klaus Aschenbrenner\01_SQL Server 2017\airports.txt'
WITH
(
    FIRSTROW = 1,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
)
GO

-- Import the routes into the staging table
BULK INSERT Routes_Staging
FROM 'C:\Users\Boss\Desktop\DEMOS\Neuerungen 2017\Klaus Aschenbrenner\01_SQL Server 2017\routes.txt'
WITH
(
    FIRSTROW = 1,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
)
GO

-- Remove the double quotes from the imported data...
UPDATE Airports_Staging
SET Name = REPLACE(Name, CHAR(34), '')
UPDATE Airports_Staging
SET City = REPLACE(City, CHAR(34), '')
UPDATE Airports_Staging
SET Country = REPLACE(Country, CHAR(34), '')
UPDATE Airports_Staging
SET IATA = REPLACE(IATA, CHAR(34), '')
UPDATE Airports_Staging
SET ICAO = REPLACE(ICAO, CHAR(34), '')
UPDATE Airports_Staging
SET DST = REPLACE(DST, CHAR(34), '')
UPDATE Airports_Staging
SET TzDatabaseTime = REPLACE(TzDatabaseTime, CHAR(34), '')
UPDATE Airports_Staging
SET Type = REPLACE(Type, CHAR(34), '')
UPDATE Airports_Staging
SET Source = REPLACE(Source, CHAR(34), '')

-- Review the imported data
SELECT * FROM Airports_Staging
WHERE IATA = 'VIE'
GO

-- Review the imported data
SELECT * FROM Routes_Staging
WHERE SourceAirport = 'VIE'
AND Airline = 'OS'
GO

-- Create a simple node table
CREATE TABLE Airports
(
	ID INT PRIMARY KEY IDENTITY(1, 1),
	Name VARCHAR(100), 
	City VARCHAR(100),
	Country VARCHAR(100),
	IATA VARCHAR(100),
	ICAO VARCHAR(100)
) AS NODE
GO

-- Populate the Node table
INSERT INTO Airports
SELECT Name, City, Country, IATA, ICAO FROM Airports_Staging
GO

-- Review the data from the nodes table
SELECT * FROM Airports
GO

-- Create a simple edge tablee
CREATE TABLE [route]
(
	OperatedBy VARCHAR(100)
)
AS EDGE
GO

-- Populate the edge table
INSERT INTO [route]($from_id, $to_id, OperatedBy)
SELECT from_airport.$node_id, to_airport.$node_id, Airline FROM Routes_Staging r
JOIN Airports from_airport ON from_airport.IATA = r.SourceAirport
JOIN Airports to_airport ON to_airport.IATA = r.DestinationAirport
GO

-- Review the data from the edge table
SELECT * FROM [route]
GO

-- Run a simple Graph Query...
SELECT
	from_airport.IATA,
	to_airport.IATA,
	[route].OperatedBy
FROM airports from_airport, airports to_airport, [route]
WHERE MATCH(from_airport-([route])->to_airport)
AND from_airport.IATA = 'VIE'
GO

-- Clean up
USE master
GO

DROP DATABASE GraphDatabase
GO