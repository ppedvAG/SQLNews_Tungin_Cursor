/*************************************************************************
 This sample targets DataWarehouse workload. We recommend using clustered 
 columnstore index for large tables (million+) rows and traditional rowstore
 for tables of size < 1 million rows. The examples here are based on star schema
 consisting of FACT and DIMENSION tables.The examples hi-light the both the 
 storage savings and performance enhancements available in SQL Server 2016.

 We have two fact tables FactResellerSalesXL_CCI and FactResellerSalesXL_PageCompressed.
 They are identical except one table is based on clustered columnstore index
 and other table is regular rowstore table with PAGE compression

NOTE: As a pre-requisite download and restore the AdventureworksDW2016_EXT database
*************************************************************************
*/
Use AdventureworksDW2016_EXT
go


/*************************************************************************************
STEP 1 - Space comparison between CCI and PAGE compressed table
**********************************************************************************/
-- How about space? Data space is much smaller. One key point to note is that PAGE compression can 
-- compress 2-4x. The difference is less as we have a Primary Key on the table that creates a Unique Non-clustered index
-- The actual data compression savings will depend upon the data and the schema
sp_spaceused 'FactResellerSalesXL_CCI'
GO
sp_spaceused 'FactResellerSalesXL_PageCompressed'
GO

-- Validate that both tables have the same amount of rows
SELECT count(*) as CCITableCount
FROM FactResellerSalesXL_CCI
GO
SELECT count(*) as PageCompressedTableCount
FROM FactResellerSalesXL_PageCompressed
GO

-- You can query the following DMV to show that most data in CCI is compressed
SELECT *
FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = object_id('FactResellerSalesXL_CCI')



/*********************************************************************
Step 2 -- Overview
-- Page Compressed BTree table v/s Columnstore table performance differences
-- Enable actual Query Plan in order to see Plan differences when Executing
*/
USE AdventureworksDW2016_EXT
GO

-- Ensure Database is in 130 compatibility mode
ALTER DATABASE AdventureworksDW2016_EXT SET compatibility_level = 130
GO
DBCC DROPCLEANBUFFERS
GO

-- Execute a typical query that joins the Fact Table with dimension tables
-- Note this query will run on the Page Compressed table, Note down the time
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

SELECT c.CalendarYear
	,b.SalesTerritoryRegion
	,FirstName + ' ' + LastName AS FullName
	,count(SalesOrderNumber) AS NumSales
	,sum(SalesAmount) AS TotalSalesAmt
	,Avg(SalesAmount) AS AvgSalesAmt
	,count(DISTINCT SalesOrderNumber) AS NumOrders
	,count(DISTINCT ResellerKey) AS NumResellers
FROM FactResellerSalesXL_PageCompressed a
INNER JOIN DimSalesTerritory b ON b.SalesTerritoryKey = a.SalesTerritoryKey
INNER JOIN DimEmployee d ON d.Employeekey = a.EmployeeKey
INNER JOIN DimDate c ON c.DateKey = a.OrderDateKey
WHERE b.SalesTerritoryKey = 3
	AND c.FullDateAlternateKey BETWEEN '1/1/2006' AND '1/1/2010'
GROUP BY b.SalesTerritoryRegion,d.EmployeeKey,d.FirstName,d.LastName,c.CalendarYear
GO

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO





-- This is the same Prior query on a table with a Clustered Columnstore index CCI 
-- The comparison numbers are even more dramatic the larger the table is, this is a 11 million row table only.
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

SELECT b.SalesTerritoryRegion
	,FirstName + ' ' + LastName AS FullName
	,count(SalesOrderNumber) AS NumSales
	,sum(SalesAmount) AS TotalSalesAmt
	,Avg(SalesAmount) AS AvgSalesAmt
	,count(DISTINCT SalesOrderNumber) AS NumOrders
	,count(DISTINCT ResellerKey) AS NumResellers
FROM FactResellerSalesXL_CCI a
INNER JOIN DimSalesTerritory b ON b.SalesTerritoryKey = a.SalesTerritoryKey
INNER JOIN DimEmployee d ON d.Employeekey = a.EmployeeKey
INNER JOIN DimDate c ON c.DateKey = a.OrderDateKey
WHERE b.SalesTerritoryKey = 3
	AND c.FullDateAlternateKey BETWEEN '1/1/2006' AND '1/1/2010'
GROUP BY b.SalesTerritoryRegion,d.EmployeeKey,d.FirstName,d.LastName,c.CalendarYear
GO

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO




/*************************************************************************************
STEP 3 - Constraints
*********************************************************************************
*/
-- SQL 2014 did not support foreign Key constraints.. 
-- Validate there are constraints on this table
SELECT * FROM sys.indexes WHERE object_id = object_id('FactResellerSalesXL_CCI')
SELECT * FROM sys.foreign_keys WHERE parent_object_id = object_id('FactResellerSalesXL_CCI')

-- Now make change to violate constraint and it should fail.
BEGIN TRAN
DECLARE @SalesOrderNumber NVARCHAR(25)

SET @SalesOrderNumber = (
		SELECT TOP 1 SalesOrderNumber
		FROM FactResellerSalesXL_CCI
		)

UPDATE FactResellerSalesXL_CCI
SET ProductKey = - 999
WHERE SalesOrderNumber = @SalesOrderNumber
ROLLBACK



/*************************************************************************************
STEP 4 - Segment Elimination Diagnostics

-- How about just a normal where clause on the OrderDateKey
-- Can we see Segments eliminated in the stats IO output
-- Look at the messages Tab and you should get what Segments are being eliminated
-- Table 'FactResellerSales_CCI'. Segment reads 1, segment skipped 11.
-- Can I get the same from the Plan? You have to look at the XML Plan

 <RunTimeInformation>
     <RunTimeCountersPerThread Thread="0" ActualRows="77313" Batches="158" ActualEndOfScans="0" 
	 ActualExecutions="1" ActualExecutionMode="Batch" SegmentReads="1" SegmentSkips="11" />
 </RunTimeInformation> 
 *****************************************************************************************
*/
SET STATISTICS IO ON
GO
SELECT OrderDateKey FROM FactResellerSalesXL_CCI
WHERE OrderDateKey > 20141201
GO

SET STATISTICS IO OFF
GO


/*************************************************************************************
STEP 5 - Batch  Mode improvements under compatibility mode 130
**********************************************************************************/
-- Enable Actual QUery Plans for this exercise
-- Hover your mouse over the SORT operator, you will see that the SORT is in batch mode.
-- See the "ACTUAL EXECUTION MODE".. A few operators that were in Row mode in SQL 2014 are now in BATCH mode.

SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

SELECT ProductKey
	,count(ProductKey)
FROM FactResellerSalesXL_CCI
GROUP BY ProductKey
ORDER BY ProductKey

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO


/*****************************************************************************
-- Batch Mode for serial ( Serial plan aka maxdop 1  in 2014 was in row mode)
-- Again hover over the SCAN node in the query plan and you will see that it is
-- in BATCH mode
***************************************************************************/
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

SELECT ProductKey,sum(TotalProductCost)
FROM FactResellerSalesXL_CCI
GROUP BY ProductKey
OPTION (MAXDOP 1)
GO


-- set Database in 120 compatibility mode
ALTER DATABASE AdventureworksDW2016_EXT SET compatibility_level = 120
GO
-- you will see that this query now runs in rowmode (much slower)
SELECT ProductKey,sum(TotalProductCost)
FROM FactResellerSalesXL_CCI
GROUP BY ProductKey
OPTION (MAXDOP 1)
GO

-- Ensure Database is back in 130 compatibility mode
ALTER DATABASE AdventureworksDW2016_EXT SET compatibility_level = 130
GO
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO




/*****************************************************************************
 Batch mode for Windows aggregates
******************************************************************************/
-- you will see that this query runs with in BATCH mode
SELECT ProductKey,OrderDateKey
	,LEAD(OrderQuantity, 1, 0) OVER (ORDER BY OrderDateKey) AS NextQuota
FROM FactResellerSalesXL_CCI
WHERE orderdatekey IN (	20060301,20060601)

-- set Database in 120 compatibility mode
ALTER DATABASE AdventureworksDW2016_EXT SET compatibility_level = 120
GO

-- you will see that this query now runs in rowmode (much slower)
SELECT ProductKey	,OrderDateKey
	,LEAD(OrderQuantity, 1, 0) OVER (ORDER BY OrderDateKey) AS NextQuota
FROM FactResellerSalesXL_CCI
WHERE orderdatekey IN (	20060301,20060601)

-- Ensure Database is back in 130 compatibility mode
ALTER DATABASE AdventureworksDW2016_EXT SET compatibility_level = 130
GO

-- Multiple distinct batch mode ( was row mode in SQL 2014)
-- In SQL 2014 the hash match would be ROW mode, and all upstream operators would be row mode.
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

SELECT ProductKey
	,COUNT(DISTINCT rs.EmployeeKey) AS NumEmployees
	,COUNT(DISTINCT rs.ResellerKey) AS NumResellers
FROM dbo.FactResellerSalesXL_CCI AS rs
WHERE rs.SalesTerritoryKey >= 8
GROUP BY ProductKey
ORDER BY ProductKey;
GO

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO



/*************************************************************************************
STEP 6 - Aggregate Pushdown
**********************************************************************************/

SET STATISTICS IO ON
SET STATISTICS TIME ON

-- Scalar aggregate pushdown without groupby is implemented.
-- Look at the Rows coming out of the SCAN, invariably in the past, 11 million rows would flow out and be filtered to 1 row
SELECT sum(TotalProductCost)
FROM FactResellerSalesXL_CCI

-- Aggregate Pushdown for a groupby supported as well
SELECT ProductKey
	,count(*)
FROM FactResellerSalesXL_CCI
GROUP BY ProductKey

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO





/*************************************************************************************
STEP 7 - String Predicate Pushdown
**********************************************************************************/
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO
DBCC DROPCLEANBUFFERS
GO

-- Look at the Query Plan, you will see the Predicate pushed to the SCAN
-- In SQL 2014, this would be a SCAN followed by a Filter
-- Look at the Properties of the SCAN, you will see a Predicate:  [AdventureworksDW2014].[dbo].[FactResellerSalesXL_CCI].[CustomerPONumber]=[@1]
SELECT CustomerPONumber
FROM FactResellerSalesXL_CCI
WHERE CustomerPONumber = N'PO1022545'

-- set Database in 120 compatibility mode
ALTER DATABASE AdventureworksDW2016_EXT SET compatibility_level = 120
GO
DBCC DROPCLEANBUFFERS
GO

-- you will see that this query now runs in rowmode (much slower)
SELECT CustomerPONumber
FROM FactResellerSalesXL_CCI
WHERE CustomerPONumber = N'PO1022545'

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

-- Ensure Database is back in 130 compatibility mode
ALTER DATABASE AdventureworksDW2016_EXT SET compatibility_level = 130
GO


/*************************************************************************************
STEP 8 - Non-Clustered Indexes ( btree)  on top of Clustered columnstore index 
**********************************************************************************/
-- What abount narrow lookups
-- See missing index for this Plan
-- Also notice no segments were eliminated . There is an optimization where you see a PROBE BITMAP filter pushed to the SCAN

DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

SELECT OrderDate
	,SalesAmount
FROM FactResellerSalesXL_CCI a
INNER JOIN DimReseller b ON a.ResellerKey = b.ResellerKey
WHERE b.ResellerName = 'Wheels Inc.'
GO

SET STATISTICS TIME OFF
SET STATISTICS IO OFF
GO


/* Now create the missing index */
CREATE NONCLUSTERED INDEX IndFactResellerSalesXL_CCI_NCI ON [dbo].[FactResellerSalesXL_CCI] ([ResellerKey]) 
INCLUDE ([SalesAmount],[OrderDate])

-- After NCI creation what does the plan look like?
-- Notice the Join has changed from Hash join to a nested loop join
-- Also the inner branch of the nested loop is a seek
-- And IO done is far less and time should be less too in particular CPU time
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

SELECT OrderDate
	,SalesAmount
FROM FactResellerSalesXL_CCI a
INNER JOIN DimReseller b ON a.ResellerKey = b.ResellerKey
WHERE b.ResellerName = 'Wheels Inc.'

SET STATISTICS TIME OFF
SET STATISTICS IO OFF
GO

-- drop the index just created
--Drop index [FactResellerSales_CCI].IndFactResellerSales_CCI_NCI
DROP INDEX IF EXISTS [FactResellerSales_CCI].IndFactResellerSales_CCI_NCI;

/*************************************************************************************
STEP 9 - Read Committed Snapshot Isolation 
**********************************************************************************/
-- RCSI now supported now, which means you can have CCI on AlwaysOn secondaries
-- Note this may be blocked if you have other connections opened
ALTER DATABASE AdventureworksDW2016_EXT SET READ_COMMITTED_SNAPSHOT ON
GO
ALTER DATABASE AdventureworksDW2016_EXT SET ALLOW_SNAPSHOT_ISOLATION ON
GO


-- Now run a Snapshot isolation transaction
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
GO
BEGIN TRAN
SELECT TOP 10 * FROM FactResellerSalesXL_CCI
COMMIT
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- Revert back if needed
ALTER DATABASE AdventureworksDW2016_EXT SET READ_COMMITTED_SNAPSHOT OFF
GO
ALTER DATABASE AdventureworksDW2016_EXT SET ALLOW_SNAPSHOT_ISOLATION OFF
GO



/*************************************************************************************
STEP 10 - Diagnostics and DMVs
**********************************************************************************/
-- New DMV
-- See in particular the trim_reason_description which will give you why the rowgroup was closed ( if at all ) before the 1 million mark
-- In this case all of them have 1 million except one, which has the trim_reason_description as REORG
SELECT * FROM sys.dm_db_column_store_row_group_physical_stats


-- Do we see NCI metadata?
-- Should appear like any Non clustered index.
SELECT * FROM sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL)
WHERE database_id = db_id()	AND object_id = object_id('FactResellerSalesXL_CCI')


-- Metadata for Columnstore indexes
-- This is a new DMV that gives you Usage data like index operational stats for columnstores
-- You can see which rowgroups are scanned how often, locking on rowgroups, latching on row groups
-- Also io_latch waits on rowgroups that indicate Io bottleneck
SELECT * FROM sys.dm_db_column_store_row_group_operational_stats


/*************************************************************************************
STEP 11 - Parallel Insert select in compat mode 130
**********************************************************************************/
-- Demo parallel Insert from staging table
DROP TABLE IF EXISTS [FactResellerSalesXL_CCI_temp];

-- create ccitest_temp and create a columnstore index
SELECT * INTO FactResellerSalesXL_CCI_temp FROM FactResellerSalesXL_CCI WHERE 1 = 2
CREATE CLUSTERED columnstore INDEX cci_temp ON FactResellerSalesXL_CCI_temp


-- Note this inserts rows in parallel
-- You need the TABLOCK hint
INSERT INTO FactResellerSalesXL_CCI_temp WITH (TABLOCK)
SELECT TOP 400000 * FROM FactResellerSalesXL_CCI


-- check the rowgroups created.
-- you will notice each  thread creates its own delta rowgroup. The compressed rowgproup will only be created 
-- if number of rows inserted by a thread is > 100k
SELECT * FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = object_id('FactResellerSalesXL_CCI_temp')



/*************************************************************************************
STEP 12 - Supportability - Index REORGANIZE and MERGE
**********************************************************************************/
-- Force the compression of all rowgroups
ALTER INDEX cci_temp on FactResellerSalesXL_CCI_temp REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON)

-- Note that all delta RGs were compressed
-- Also note, that this DMV provides much richer set of information such as why a rowgroup was compressed
SELECT * FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = object_id('FactResellerSalesXL_CCI_temp')


-- Now delete a subset of rows 
DELETE FactResellerSalesXL_CCI_temp WHERE productkey % 2 = 0

-- run the following DMV to note the deleted rows
SELECT * FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = object_id('FactResellerSalesXL_CCI_temp')


-- we will now run REORG command to defragement the columnstore index by removing deleted rows
ALTER INDEX cci_temp on FactResellerSalesXL_CCI_temp REORGANIZE 

-- This will MERGE smaller rowgroups into larger rowgroups and also reclaim space from the deleted rows
-- http://blogs.msdn.com/b/sqlcat/archive/2015/08/17/sql-2016-columnstore-row-group-merge-policy-and-index-maintenance-improvements.aspx 
ALTER INDEX cci_temp on FactResellerSalesXL_CCI_temp REORGANIZE

-- Validate the new rowgroups that were merged 
-- Note only look at the COMPRESSED rowgroup.
SELECT * FROM sys.dm_db_column_store_row_group_physical_stats
WHERE object_id = object_id('FactResellerSalesXL_CCI_temp')





