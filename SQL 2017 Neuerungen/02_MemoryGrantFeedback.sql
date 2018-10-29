
SET STATISTICS IO, TIME ON
GO

USE master
GO

-- Create a new database
CREATE DATABASE MemoryGrantFeedback
GO

USE MemoryGrantFeedback
GO

-- Create a test table
CREATE TABLE Table1
(
	Column1 INT IDENTITY PRIMARY KEY,
	Column2 INT,
	Column3 CHAR(2000)
)
GO

-- Create a Non-Clustered Index on column Column2
CREATE NONCLUSTERED INDEX idxTable1_Column2 ON Table1(Column2)
GO

-- Insert 1500 records into Table1
SELECT TOP 1500 IDENTITY(INT, 1, 1) AS n INTO #Nums
FROM
master.dbo.syscolumns sc1

INSERT INTO Table1 (Column2, Column3)
SELECT n, REPlICATE('x', 2000) FROM #nums
DROP TABLE #nums
GO

-- Retrieve the inserted records
SELECT * FROM Table1
GO

-- Select a record through the previous created Non-Clustered Index from the table.
-- SQL Server retrieves the record through a Non-Clustered Index Seek operator.
-- SQL Server estimates for the sort operator 1 record, which also reflects the actual number of rows.
-- SQL Server requests a memory grant of 1.204kb - the sorting is done inside the memory.
-- Logical reads: 4
DECLARE @x INT

SELECT @x = column2 FROM Table1
WHERE Column2 = 2
ORDER BY Column3
GO

-- Insert 799 records into table Table1
SELECT TOP 799 IDENTITY(INT, 1, 1) AS n INTO #Nums
FROM
master.dbo.syscolumns sc1

INSERT INTO Table1 (Column2, Column3)
SELECT 2, REPLICATE('x', 2000) FROM #nums
DROP TABLE #nums
GO

-- SQL Server estimates now 1 record for the sort operation and requests a memory grant of 1.024kb for the query.
-- This is too less, because actually we are sorting 800 rows!
-- SQL Server has to spill the sort operation into TempDb, which now becomes a physical I/O operation!!!
-- The query requests 1024KB of memory, which is too less
-- Logical reads: 1605
DECLARE @x INT

SELECT @x = column2 FROM Table1
WHERE Column2 = 2
ORDER BY Column3
GO

-- Let's "enable" the Memory Grant Feedback by creating a dummy ColumnStore Index...
CREATE NONCLUSTERED COLUMNSTORE INDEX dummy ON Table1(Column1)
WHERE Column1 = -1 and Column1 = -2
GO

-- The query doesn't spill over to TempDb anymore, because we request
-- 298198KB of memory - which is too much!
DECLARE @x INT

SELECT @x = column2 FROM Table1
WHERE Column2 = 2
ORDER BY Column3
GO

-- When we execute the query again, the Memory Grant is now finally
-- adjusted to 3072KB, which is again a little bit too much...
DECLARE @x INT

SELECT @x = column2 FROM Table1
WHERE Column2 = 2
ORDER BY Column3
GO

-- When we execute the query again, the Memory Grant is now finally
-- adjusted to 1704KB, which work perfectly for this query.
DECLARE @x INT

SELECT @x = column2 FROM Table1
WHERE Column2 = 2
ORDER BY Column3
GO

-- Clean up
USE master
GO

DROP DATABASE MemoryGrantFeedback
GO