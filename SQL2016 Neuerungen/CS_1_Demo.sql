CREATE DATABASE [CS]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'CS', FILENAME = N'C:\_BOOMDB\CS.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'CS_log', FILENAME = N'C:\_BOOMDB\CS_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
GO

USE [CS]
GO




select * into Umsatz from nwindbig.dbo.umsatz
GO

insert into umsatz
select * from umsatz
GO 
--Vergleichstabelle
Select * into UmsatzTab from umsatz 
GO


USE [CS]
GO

CREATE CLUSTERED COLUMNSTORE INDEX [CSIX]
	 ON [dbo].[Umsatz] WITH
	  (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)

GO

ALTER TABLE [dbo].[Umsatz] REBUILD PARTITION = ALL
WITH 
(DATA_COMPRESSION = COLUMNSTORE_ARCHIVE)

--NON Clusterd CS IX gefiltert..nicht mit bestehenden CS kombinierbar
Create NONCLUSTERED Columnstore index NCCS_Orderdate
ON
dbo.umsatztab
	(
	orderdate,	freight,
	quantity,
	unitprice
	)
where (orderdate < '1.1.1998')
with (Drop_existing=Off, compression_delay=30)

--in Memory gefiltert

CREATE DATABASE [imOLTP]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'imOLTP', FILENAME = N'C:\_BOOMDB\imOLTP.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB ), 
 FILEGROUP [IM] CONTAINS MEMORY_OPTIMIZED_DATA 
( NAME = N'imoltpFiles', FILENAME = N'C:\_BOOMDB\imoltp' )
 LOG ON 
( NAME = N'imOLTP_log', FILENAME = N'C:\_BOOMDB\imOLTP_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
GO


USE [imoltp]
GO

CREATE TABLE [dbo].[UmsatzCSIXim](
	[CustomerID] [nchar](5) NOT NULL,
	[CompanyName] [nvarchar](40) NOT NULL,
	[City] [nvarchar](15) NULL,
	[Country] [nvarchar](15) NULL,
	[LastName] [nvarchar](20) NOT NULL,
	[FirstName] [nvarchar](10) NOT NULL,
	[Title] [nvarchar](30) NULL,
	[BirthDate] [datetime] NULL,
	[EmployeeID] [int] NULL,
	[OrderDate] [datetime] NULL,
	[RequiredDate] [datetime] NULL,
	[Freight] [money] NULL,
	[ShipCity] [nvarchar](15) NULL,
	[ShipCountry] [nvarchar](15) NULL,
	[UnitPrice] [money] NOT NULL,
	[Quantity] [smallint] NOT NULL,
	[ProductName] [nvarchar](40) NOT NULL,
	[ProductID] [int] NOT NULL,
	Constraint PK_CUSTOrder_CSIXIM Primary key
	Nonclustered hash (customerid)
			With (Bucket_COUNT=1000000),
	Index IMOrderdate NonCLustered (orderdate),

	Index IMProductid Clustered Columnstore
		With (compression_Delay=60)
)
With (memory_optimized= ON,
	 durability= Schema_AND_DATA)
GO
	









use imoltp
GO
CREATE TABLE imCSAccount (  
    accountkey int NOT NULL PRIMARY KEY NONCLUSTERED,  
    Accountdescription nvarchar (50),  
    accounttype nvarchar(50),  
    unitsold int,  
    INDEX imaccount_cci CLUSTERED COLUMNSTORE  
    )  
    WITH (MEMORY_OPTIMIZED = ON );  
GO  