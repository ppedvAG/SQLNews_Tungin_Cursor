use AdventureworksDW2016_EXT;
go
-- Set compatibility level of SQL Server 2016
alter database AdventureworksDW2016_EXT set compatibility_level = 130;
go
-- Create multistatement table-valued function
create or alter function dbo.uf(@n int)
returns @t table(SalesOrderNumber nvarchar(40), SalesOrderLineNumber tinyint)
with schemabinding
as
begin
 
	insert @t(SalesOrderNumber, SalesOrderLineNumber)
	select top(@n)
		SalesOrderNumber, 
		SalesOrderLineNumber
	from
		dbo.FactResellerSalesXL_CCI;
 
	return;
end
go
-- Clear procedure cache for DB
alter database scoped configuration clear procedure_cache;
go
-- Run the query with mTVF
set statistics xml on;
select
	c = count_big(*)
from
	dbo.FactResellerSalesXL_CCI c 
	join dbo.uf(10000) t on t.SalesOrderNumber = c.SalesOrderNumber and t.SalesOrderLineNumber = c.SalesOrderLineNumber
;
set statistics xml off;


--Mit Recompile
-- Create multistatement table-valued function
create or alter function dbo.uf(@n int)
returns @t table(SalesOrderNumber nvarchar(40), SalesOrderLineNumber tinyint)
with schemabinding
as
begin
 
	insert @t(SalesOrderNumber, SalesOrderLineNumber)
	select top(@n)
		SalesOrderNumber, 
		SalesOrderLineNumber
	from
		dbo.FactResellerSalesXL_CCI
	option(recompile);
 
	return;
end
go
 
-- Clear procedure cache for DB
alter database scoped configuration clear procedure_cache;
go
-- Run the query with mTVF
set statistics xml on;
declare @n int = 10001
select
	c = count_big(*)
from
	dbo.FactResellerSalesXL_CCI c 
	join dbo.uf(10000) t on t.SalesOrderNumber = c.SalesOrderNumber and t.SalesOrderLineNumber = c.SalesOrderLineNumber
option(recompile)
;
set statistics xml off;
go

--Bringt nix



--Jetzt Lvl 140
alter database AdventureworksDW2016_EXT set compatibility_level = 140;
go
-- Create multistatement table-valued function
create or alter function dbo.uf(@n int)
returns @t table(SalesOrderNumber nvarchar(40), SalesOrderLineNumber tinyint)
with schemabinding
as
begin
 
	insert @t(SalesOrderNumber, SalesOrderLineNumber)
	select top(@n)
		SalesOrderNumber, 
		SalesOrderLineNumber
	from
		dbo.FactResellerSalesXL_CCI;
 
	return;
end
go
-- Clear procedure cache for DB
alter database scoped configuration clear procedure_cache;
go
-- Run the query with mTVF
set statistics xml on;
select
	c = count_big(*)
from
	dbo.FactResellerSalesXL_CCI c 
	join dbo.uf(10000) t on t.SalesOrderNumber = c.SalesOrderNumber and t.SalesOrderLineNumber = c.SalesOrderLineNumber
option(use hint('DISABLE_BATCH_MODE_ADAPTIVE_JOINS')) -- disable adaptive join
;
set statistics xml off;
go