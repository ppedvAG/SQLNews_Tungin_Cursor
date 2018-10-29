--Nativ komplilierte Prozeduren

--seit SQL 20172016 auch CASE und skalale UNterabfragen, TOP, Distinct, UNION
--Filter: Between, in OR, NOT, EXISTS, IS NOT, GROUP BY (MIN MAX aber nicht bei allen Datentypen)
--TOP nicht mit percent oder with ties
--While, Retrun, if else

--einfache Proc: Wie gehts?

CREATE PROCEDURE testTop  
WITH EXECUTE AS OWNER, SCHEMABINDING, NATIVE_COMPILATION  
  AS  
  BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')  
    SELECT TOP 8192 ShoppingCartId, CreatedDate, TotalPrice FROM dbo.ShoppingCart  
    ORDER BY ShoppingCartId DESC  
  END;  
GO



---TEST Beispiel
---Normale Prozedur

use AdventureWorks2014;
GO

DROP Procedure if exists get_email_address_data;
GO

CREATE PROCEDURE get_email_address_data   ( @BusinessEntityID INT = NULL )
AS
    BEGIN
			DECLARE @T DATETIME, @F BIGINT;
		SET @T = GETDATE();
		WHILE DATEADD(SECOND,30,@T)>GETDATE()
			SET @F=POWER(2,30);
        IF @BusinessEntityID IS NULL
            BEGIN
                SELECT  BusinessEntityID ,EmailAddressID , EmailAddress FROM    Person.EmailAddress
            END
        ELSE
            BEGIN
                SELECT  BusinessEntityID ,  EmailAddressID , EmailAddress FROM    person.EmailAddress
                WHERE   BusinessEntityID = @BusinessEntityID
            END
		If @BusinessEntityID < 1000
			BEGIN
				select @BusinessEntityID/2
			END
		ELSE
			BEGIN
				IF  @BusinessEntityID >5000 select (@BusinessEntityID/3)*4 
		
		END
	
		END
GO

----TEST: PLAN!
DBCC FREEPROCCACHE
SET STATISTICS IO ON
SET STATISTICS TIME ON
EXEC get_email_address_data @BusinessEntityID = 12894

---TEST: Dauer
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
EXEC get_email_address_data @BusinessEntityID = 12894
GO 10


---TESTVERFAHREN MIT IM und Native Compiled
use AdventureWorks2016_EXT;
GO

CREATE TABLE dbo.EmailAddress
(
    BusinessEntityID INT NOT NULL PRIMARY KEY NONCLUSTERED HASH WITH (BUCKET_COUNT = 30000),
    EmailAddressID INT IDENTITY(1,1) NOT NULL,
    EmailAddress NVARCHAR(50) COLLATE Latin1_General_BIN2 NOT NULL INDEX ix_EmailAddress NONCLUSTERED HASH(EmailAddress)WITH (BUCKET_COUNT = 30000),
    rowguid UNIQUEIDENTIFIER  NOT NULL CONSTRAINT DF_EmailAddress_rowguid DEFAULT (NEWID()),
       ModifiedDate DATETIME NOT NULL CONSTRAINT DF_EmailAddress_ModifiedDate DEFAULT (GETDATE()),
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
GO

CREATE STATISTICS stats_EmailAddress_BusinessEntityID
    ON Person.EmailAddress (BusinessEntityID) WITH FULLSCAN, NORECOMPUTE
UPDATE STATISTICS Person.EmailAddress WITH FULLSCAN, NORECOMPUTE

-- Populate our email address table with its original contents
--Zzwischenschritt mit #t, da keine DB CrossAbfragen ausgefürht werden dürfen
select * into #t from adventureWorks2014.person.EmailAddress
GO

--nun einfügen aus #t
INSERT  INTO dbo.EmailAddress
        ( BusinessEntityID ,  EmailAddress , rowguid , ModifiedDate )
        SELECT  BusinessEntityID , EmailAddress , rowguid ,  ModifiedDate FROM    #t
        ORDER BY EmailAddressID
GO

--PROC nun nativ Compiled

DROP Procedure if exists get_email_address_data_IM;
GO

CREATE PROCEDURE get_email_address_data_IM (@BusinessEntityID INT = NULL)
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS Owner
AS
BEGIN ATOMIC
WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')
       DECLARE @T DATETIME, @F BIGINT;
		SET @T = GETDATE();
		WHILE DATEADD(SECOND,30,@T)>GETDATE() SET @F=POWER(2,30);
	   IF @BusinessEntityID IS NULL
       BEGIN
              SELECT
                     BusinessEntityID,EmailAddressID, EmailAddress FROM dbo.EmailAddress
       END
       ELSE
       BEGIN
              SELECT
                     BusinessEntityID, EmailAddressID,EmailAddress  FROM dbo.EmailAddress
              WHERE BusinessEntityID = @BusinessEntityID
       END
	   If @BusinessEntityID < 1000
			BEGIN
				select @BusinessEntityID/2
			END
		ELSE
			BEGIN
				IF  @BusinessEntityID >5000 select (@BusinessEntityID/3)*4 
		
			END
		
	END
GO


--TESTLAUF mit im Tabelle und nc Proc


----TEST: PLAN!
DBCC FREEPROCCACHE
SET STATISTICS IO ON
SET STATISTICS TIME ON
EXEC get_email_address_data_IM @BusinessEntityID = 12894


---TEST: Dauer
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
EXEC get_email_address_data_IM @BusinessEntityID = 12894
GO 10

