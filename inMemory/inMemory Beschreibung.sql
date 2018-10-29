--inMemory


/* eingeführt 2014

--> viele "Mängel"

ab SQL 2016

PK--FK Beziehungen
(aber nur innerhalb von imTabellen

NUll Werte zulässig in nicht eindeutigen Indizes

Encryption nicht supported
Row Level wird supported.. Prozeduren und F() müssen aber nativ kompiliert sein

Änderbar

stat auch mit Fullscan

nun auch in NatCompProc: OUTPUT-Klausel, UNION und UNION ALL, DISTINCT, OUTER JOINs, Unterabfragen.

auch alter Proc

nun auch parallel scan Modus

plus Columnstore


Nonclustered Columnstore Index zusätzlich zu dem Clustered Index 
sowie den Non Clustered Index gefiltert


Real Time
memory-optimierten Tabellen und ColumnStore 

Clustered Columnstore läßt Hot Daten aus 
	geänderte Daten (ins, up) sind in delta Stores (Heap)
	del sind extra Tabellen (eigtl Bitmap Filter)
den memory-optimierten Index deckt die Hot Data im Delta Store ab


*/

CREATE TABLE dbo.ImTabelle
(
	SP1  int NOT NULL, 
	sp2  int NOT NULL,
	sp3  int NOT NULL  INDEX IXim NONCLUSTERED HASH With (Bucket_Count=1000), 
   CONSTRAINT 
		PKIM PRIMARY KEY NONCLUSTERED (SP1),
        INDEX IXIM2 HASH (sp2) WITH (BUCKET_COUNT = 1024)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY =  SCHEMA_ONLY)
GO


SELECT
  POWER( 2,CEILING( LOG( COUNT( 0)) / LOG( 2)))
    AS 'BUCKET_COUNT'
FROM   (SELECT DISTINCT sp2 FROM imTabelle) T




select * from sys.dm_db_xtp_hash_index_stats

----------------GESAMTE DEMO
CREATE DATABASE TestDB
ON PRIMARY
  (NAME = TestDB_file1,
    FILENAME = N'C:\_SQLDB\TestDB_1.mdf',
          SIZE = 100MB,          
          FILEGROWTH = 10%),
FILEGROUP TestDB_MemoryOptimized_filegroup CONTAINS MEMORY_OPTIMIZED_DATA
  ( NAME = TestDB_MemoryOptimized,
    FILENAME = N'C:\_SQLDB\TestDB_MemoryOptimized')
LOG ON
  ( NAME = TestDB_log_file1,
    FILENAME = N'C:\_SQLDB\TestDB_1.ldf',
          SIZE = 100MB,          
          FILEGROWTH = 10%)
GO


--NUr 4 Buckets
USE TestDB
GO
IF OBJECT_ID('dbo.Customers','U') IS NOT NULL
    DROP TABLE dbo.Customers
GO


CREATE TABLE dbo.Customers(
  CustomerId        INT NOT NULL,
  CustomerCode      NVARCHAR(10) NOT NULL,
  CustomerName      NVARCHAR(50) NOT NULL,
  CustomerAddress   NVARCHAR(50) NOT NULL,
  ChkSum            INT NOT NULL 
    PRIMARY KEY NONCLUSTERED HASH (customerid) WITH (BUCKET_COUNT = 4)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
GO

--99999 Zeilen
USE TestDB
GO
DECLARE @i  int = 1
WHILE @i < 100000
BEGIN
    INSERT INTO dbo.customers
    SELECT @i,  
    CONVERT(VARCHAR(10), GETDATE() ,13 ),
    CONVERT(VARCHAR(12), GETDATE() , 103 ),
    CONVERT(VARCHAR(12), GETDATE() , 103 ),
    CHECKSUM(GETDATE() )
    SET @i = @i +1
END


---Statistiken : --avg und max ...
USE TestDB
GO
SELECT  s.object_id ,
        OBJECT_NAME(s.object_id) AS 'Table Name' ,
        s.index_id ,
        i.name ,
        s.total_bucket_count ,
        s.empty_bucket_count ,
        s.avg_chain_length ,
        s.max_chain_length
FROM    sys.dm_db_xtp_hash_index_stats s
        INNER JOIN sys.hash_indexes i 
    ON  s.object_id = i.object_id
    AND s.index_id = i.index_id


---DEMO: Abfrage auf Bereiche.. keine gute Idee bei Hashwerten ..vor allem mit geringen Bucket
--und langer chaín

USE TestDB
GO
SELECT  s.object_id ,
        OBJECT_NAME(s.object_id) AS 'Table Name' ,
        s.index_id ,
        i.name ,
        s.total_bucket_count ,
        s.empty_bucket_count ,
        s.avg_chain_length ,
        s.max_chain_length
FROM    sys.dm_db_xtp_hash_index_stats s
        INNER JOIN sys.hash_indexes i 
    ON  s.object_id = i.object_id
    AND s.index_id = i.index_id
    WHERE s.object_id = OBJECT_ID('dbo.Customers')
GO
BEGIN TRANSACTION
UPDATE dbo.Customers WITH (SNAPSHOT)
   SET ChkSum = 0
 WHERE CustomerId BETWEEN 1000 AND 3000
GO 5
SELECT  s.object_id ,
        OBJECT_NAME(s.object_id) AS 'Table Name' ,
        s.index_id ,
        i.name ,
        s.total_bucket_count ,
        s.empty_bucket_count ,
        s.avg_chain_length ,
        s.max_chain_length
FROM    sys.dm_db_xtp_hash_index_stats s
        INNER JOIN sys.hash_indexes i 
    ON  s.object_id = i.object_id
    AND s.index_id = i.index_id
    WHERE s.object_id = OBJECT_ID('dbo.Customers')
GO
ROLLBACK TRANSACTION

--Gleiche Demo mit höherem Bucket
USE TestDB
GO
SELECT
  POWER(    2,    CEILING( LOG( COUNT( 0)) / LOG( 2)))
    AS 'BUCKET_COUNT'
FROM
  (SELECT DISTINCT CustomerId       FROM dbo.Customers) T
  --131072..errechnet

--Neue Tabelle:
USE TestDB
GO
IF OBJECT_ID('dbo.Customers_New','U') IS NOT NULL
    DROP TABLE dbo.Customers_New
GO
CREATE TABLE dbo.Customers_New(
  CustomerId        INT NOT NULL,
  CustomerCode      NVARCHAR(10) NOT NULL,
  CustomerName      NVARCHAR(50) NOT NULL,
  CustomerAddress   NVARCHAR(50) NOT NULL,
  ChkSum            INT NOT NULL 
    PRIMARY KEY NONCLUSTERED HASH (CustomerId) WITH (BUCKET_COUNT = 131072)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
GO

--Daten aus Cuatomers kopieren in neue Tabelle
USE TestDB
GO
INSERT INTO dbo.Customers_New (CustomerId,
                           CustomerCode,
                           CustomerName,
                           CustomerAddress,
                           ChkSum)
   SELECT CustomerId,
          CustomerCode,
          CustomerName,
          CustomerAddress,
          ChkSum
     FROM dbo.Customers


---Abfrage neu:
USE TestDB
GO
SELECT  s.object_id ,
        OBJECT_NAME(s.object_id) AS 'Table Name' ,
        s.index_id ,
        i.name ,
        s.total_bucket_count ,
        s.empty_bucket_count ,
        s.avg_chain_length ,
        s.max_chain_length
FROM    sys.dm_db_xtp_hash_index_stats s
        INNER JOIN sys.hash_indexes i 
    ON  s.object_id = i.object_id
    AND s.index_id = i.index_id
    WHERE s.object_id = OBJECT_ID('dbo.Customers_New')
GO
BEGIN TRANSACTION
UPDATE dbo.Customers_New WITH (SNAPSHOT)
   SET ChkSum = 0
 WHERE CustomerId BETWEEN 1000 AND 3000
GO 5
SELECT  s.object_id ,
        OBJECT_NAME(s.object_id) AS 'Table Name' ,
        s.index_id ,
        i.name ,
        s.total_bucket_count ,
        s.empty_bucket_count ,
        s.avg_chain_length ,
        s.max_chain_length
FROM    sys.dm_db_xtp_hash_index_stats s
        INNER JOIN sys.hash_indexes i 
    ON  s.object_id = i.object_id
    AND s.index_id = i.index_id
    WHERE s.object_id = OBJECT_ID('dbo.Customers_New')
ROLLBACK TRANSACTION

--das war doch schneller!!