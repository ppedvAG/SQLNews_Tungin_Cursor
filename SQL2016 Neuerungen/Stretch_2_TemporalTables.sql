USE [master]
GO
 
CREATE DATABASE [TemporalStretch]
ON PRIMARY (
    NAME        = N'TemporalStretch', 
    FILENAME    = N'C:\_SQLDB\MSSQL13.MSSQLSERVER\MSSQL\DATA\TemporalStretch.mdf',
    SIZE        = 51200KB,
    MAXSIZE     = UNLIMITED,
    FILEGROWTH  = 65536KB
)
LOG ON (
    NAME        = N'TemporalStretch_log', 
    FILENAME    = N'C:\_SQLDB\MSSQL13.MSSQLSERVER\MSSQL\DATA\TemporalStretch_log.ldf',
    SIZE        = 51200KB,
    MAXSIZE     = 2048GB,
    FILEGROWTH  = 65536KB
)
GO
 
ALTER DATABASE [TemporalStretch] SET COMPATIBILITY_LEVEL = 130
GO
 
ALTER DATABASE [TemporalStretch] SET RECOVERY SIMPLE 
GO


----

USE TemporalStretch;
GO
 
IF SCHEMA_ID('hist') IS NULL
    EXEC sp_executesql N'CREATE SCHEMA hist AUTHORIZATION dbo';
GO
 
-- create products table with versioning
CREATE TABLE dbo.Product (
    ID              INT IDENTITY CONSTRAINT PK_Product PRIMARY KEY,
    Name            VARCHAR(15) NOT NULL,
    Price           SMALLMONEY,
 
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),
 
    ValidFrom       DATETIME2(0) GENERATED ALWAYS AS ROW START,
    ValidTo         DATETIME2(0) GENERATED ALWAYS AS ROW END
) WITH (
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = hist.Product)
)
 
INSERT INTO dbo.Product (Name, Price) VALUES
('Product 11', 110),
('Product 12', 120),
('Product 13', 130),
('Product 14', 140),
('Product 15', 150)
 
BEGIN TRANSACTION
INSERT INTO dbo.Product (Name, Price) VALUES
('Product 21', 210),
('Product 22', 220),
('Product 23', 230),
('Product 24', 240),
('Product 25', 250)
 
WAITFOR DELAY '00:00:05' -- 5 seconds
 
INSERT INTO dbo.Product (Name, Price) VALUES
('Product 31', 310),
('Product 32', 320),
('Product 33', 330),
('Product 34', 340),
('Product 35', 350)
 
COMMIT TRANSACTION
 
WAITFOR DELAY '00:02:00' -- 2 minutes
 
UPDATE dbo.Product SET
    Price = Price * 2.
WHERE
    Name < 'Product 20'
 
 
UPDATE dbo.Product SET
    Price = Price * 2.
WHERE
    Name BETWEEN 'Product 21' AND 'Product 25'
-- -----
WAITFOR DELAY '00:01:00' -- 1 minute
 
UPDATE dbo.Product SET
    Price = Price - 8
WHERE
    Name < 'Product 20'
 
UPDATE dbo.Product SET
    Price = Price - 14
WHERE
    Name BETWEEN 'Product 21' AND 'Product 25'





	--Stretch

Select distinct validfrom, validto from hist.product order by validto desc

select * from sys.remote_data_archive_tables