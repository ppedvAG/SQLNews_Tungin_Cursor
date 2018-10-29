--Adaptive Joins :
--Columnstore Notwendig


ALTER DATABASE [AdventureWorks2014] SET COMPATIBILITY_LEVEL = 140
GO
USE AdventureWorks2014
GO

SET STATISTICS IO, TIME ON
GO

-- Create a dummy ColumnStore Index to "fool" the Query Optimizer
CREATE NONCLUSTERED COLUMNSTORE INDEX dummy ON Sales.SalesOrderHeader(SalesOrderID)
WHERE SalesOrderID = -1 and SalesOrderID = -2
GO

	-- Run a simple query with an Adaptive Join in the Execution Plan
DECLARE @TerritoryID INT = 0

SELECT SUM(soh.SubTotal) FROM Sales.SalesOrderHeader soh
	INNER  JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
	WHERE soh.TerritoryID = @TerritoryID
	--option(querytraceon 3604, querytraceon 8607, querytraceon 7352);
	--option (optimize for (@TerritoryID = 0))
	GO



ALTER DATABASE [ContosoRetailDW] SET COMPATIBILITY_LEVEL = 140
GO
USE ContosoRetailDW
GO

-- This query can't use an Adaptive Join, because we can't seek into the FactOnlineSales table...
SELECT
      f.OnlineSalesKey, 
      f.DateKey, 
      d1.CompanyName, 
      d2.CalendarDayOfWeek
FROM FactOnlineSales f
INNER JOIN DimCustomer d1 ON d1.CustomerKey = f.CustomerKey
INNER JOIN DimDate d2 ON d2.DateKey = f.DateKey
WHERE f.DateKey >= '20090101' AND f.DateKey < '20090201'
GO

-- Let's create a supporting Non-Clustered Index to make an Adaptive Join possible
CREATE NONCLUSTERED columnstore INDEX idx_FactOnlineSales_DateKey2
ON FactOnlineSales(DateKey)

CREATE NONCLUSTERED  INDEX idx_FactOnlineSales_DateKey
ON FactOnlineSales(DateKey)
INCLUDE (OnlineSalesKey , CustomerKey)
GO
-- Now we get the Adaptive Join in the Query Plan.
-- For a lot of rows, the Adaptive Join uses the Hash Join.
SELECT
      f.OnlineSalesKey, 
      f.DateKey, 
      d1.CompanyName, 
      d2.CalendarDayOfWeek
FROM FactOnlineSales f
INNER JOIN DimCustomer d1 ON d1.CustomerKey = f.CustomerKey
INNER JOIN DimDate d2 ON d2.DateKey = f.DateKey
WHERE f.DateKey >= '20090101' AND f.DateKey < '20090201'
GO

-- For just a few rows, the Adaptive Join uses the Nested Loop Join.
SELECT 
      f.OnlineSalesKey 
   ,  f.DateKey 
     , d1.CompanyName 
    , d2.CalendarDayOfWeek
FROM FactOnlineSales f
INNER JOIN DimCustomer d1 ON d1.CustomerKey = f.CustomerKey
INNER JOIN DimDate d2 ON d2.DateKey = f.DateKey
WHERE f.DateKey > '20090101' AND f.DateKey < '20090103'
GO

-- Create a simple Stored Procedure, which wraps the SQL statement
CREATE PROCEDURE RetrieveData
(
	@FromDate DATE,
	@ToDate DATE
)
AS
	SELECT
		f.OnlineSalesKey, 
		f.DateKey, 
		d1.CompanyName, 
		d2.CalendarDayOfWeek
	FROM FactOnlineSales f
	INNER JOIN DimCustomer d1 ON d1.CustomerKey = f.CustomerKey
	INNER JOIN DimDate d2 ON d2.DateKey = f.DateKey
	WHERE f.DateKey >= @FromDate AND f.DateKey < @ToDate
GO

-- Execute the Stored Procedure - Hash Join
EXEC RetrieveData '20090101', '20090201'
GO

-- Execute the Stored Procedure - Nested Loop Join
EXEC RetrieveData '20090101', '20090102'
GO

-- Clean up
DROP INDEX idx_FactOnlineSales_DateKey ON FactOnlineSales
DROP PROCEDURE RetrieveData
GO