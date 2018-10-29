/*============================================================================
  Summary:  Demonstrates Realtime Data Analytics.
------------------------------------------------------------------------------
  Written by Klaus Aschenbrenner, www.SQLpassion.at

  For more information about SQL Server, check out my website
    http://www.SQLpassion.at
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

USE AdventureWorks2014
GO

SET STATISTICS IO, TIME ON
GO

-- Create a Non-Clustered ColumnStore Index for the "cold" data partition
CREATE NONCLUSTERED COLUMNSTORE INDEX idx_ColdData ON Sales.SalesOrderDetail(ProductID)
WHERE ModifiedDate < '20140601'
GO

-- Scans the complete Clustered Index
SELECT * FROM Sales.SalesOrderDetail
GO

-- Uses the Non-Clustered ColumnStore Index (the "cold" data partition)
SELECT ProductID FROM Sales.SalesOrderDetail 
WHERE ModifiedDate < '20140601'
GO

-- Scans the complete Clustered Index ;-(
SELECT ProductID FROM Sales.SalesOrderDetail
WHERE ModifiedDate < '20140531'
GO

-- Without a supporting Non-Clustered Index we can't access the "hot" data partition in a very
-- efficient way - we have to scan the complete Clustered Index...
-- We also have to think here about the Tipping Point in combination with Bookmark Lookups!
SELECT ProductID FROM Sales.SalesOrderDetail
WHERE ModifiedDate >= '20140601'
GO

-- Create a traditional Non-Clustered RowStore Index for the "hot" data partition
CREATE NONCLUSTERED INDEX idx_HotData ON Sales.SalesOrderDetail(ProductID)
WHERE ModifiedDate >= '20140601'
GO

-- Scans the complete Non-Clustered Index (the "hot" data partition)
SELECT ProductID FROM Sales.SalesOrderDetail
WHERE ModifiedDate >= '20140601'
GO

-- Clean up
DROP INDEX idx_HotData ON Sales.SalesOrderDetail
DROP INDEX idx_ColdData ON Sales.SalesOrderDetail
GO