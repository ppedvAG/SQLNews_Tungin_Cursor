--INMemory Demo!

Create Database inMemAdventure;
GO

use inMemAdventure;
GO

IF NOT EXISTS (SELECT * FROM sys.data_spaces WHERE TYPE='FX')
ALTER DATABASE CURRENT
         ADD FILEGROUP [imMod] CONTAINS MEMORY_OPTIMIZED_DATA
GO

:setvar checkpoint_files_location "C:\_SQLDB\"  
IF NOT EXISTS (SELECT * FROM sys.data_spaces ds JOIN sys.database_files df 
          ON ds.data_space_id=df.data_space_id WHERE ds.TYPE='FX')
ALTER DATABASE CURRENT ADD FILE (name='inMemAdventuremod', filename='$(checkpoint_files_location)inMemAdventuremod') 
        TO FILEGROUP [IMmod]


--auch READ Commited to snapshot
ALTER DATABASE CURRENT SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON


--Tabellen

 
CREATE TABLE [Sales].[SalesOrderDetail_inmem](
[SalesOrderID] UNIQUEIDENTIFIER NOT NULL INDEX IX_SalesOrderID 
HASH WITH (BUCKET_COUNT=1000000),
[SalesOrderDetailID] [int] NOT NULL,
[OrderDate] [datetime2] NOT NULL,
[OrderQty] [smallint] NOT NULL,
[ProductID] [int] NOT NULL INDEX IX_ProductID HASH WITH (BUCKET_COUNT=10000000))
/*
...
...
*/
CREATE INDEX IX_OrderDate (OrderDate ASC),
CONSTRAINT [imPK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] 
PRIMARY KEY NONCLUSTERED HASH
(
[SalesOrderID],
[SalesOrderDetailID]
) WITH (BUCKET_COUNT=10000000)
 
) WITH (MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_AND_DATA)
 

