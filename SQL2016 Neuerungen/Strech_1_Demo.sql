use master
GO

exec sys.sp_configure N'remote data archive','1';
RECONFIGURE;
GO

use northwind
GO
--Strecth auf Azure mit Umsatztabelle
select * into UmsatzArchiv from umsatz;
GO

select * from umsatzarchiv;
go

select * into UmsatzArchiv2 from umsatzarchiv;
GO

--bestehende Tabelle in Strech
ALTER TABLE UmsatzArchiv2 
   SET ( REMOTE_DATA_ARCHIVE = ON ( MIGRATION_STATE = OUTBOUND ) ) ;  
GO

--Daten mit HOT und COLD DATA
drop Table UmsatzArchiv3
GO
select * into UmsatzArchiv3 from Umsatzarchiv
go

--Filterfunktion anlegen
ALTER FUNCTION dbo.fn_stretchpredicate(@column1 datetime)
RETURNS TABLE
WITH SCHEMABINDING
AS
Return  Select 1 as is_eligible where @column1 < convert(datetime2, N'1.1.1998',101)


ALTER TABLE umsatzarchiv3
 SET ( REMOTE_DATA_ARCHIVE = ON (
    FILTER_PREDICATE =  dbo.fn_stretchpredicate(orderdate),
    MIGRATION_STATE = OUTBOUND) )


select * from umsatzarchiv3 where orderdate ='1.4.1996'
select * from umsatzarchiv3 where orderdate >'1.4.1998'


