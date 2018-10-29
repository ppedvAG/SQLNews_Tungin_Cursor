Use RowLevel
GO
revert
drop table customer



CREATE TABLE CUSTOMER (
	Customerid int identity(1,1) primary key,
	Name nvarchar(64),
	city nvarchar(20),
	Status nvarchar(64),
	EmpID int DEFAULT CAST(SESSION_CONTEXT(N'EmpID') AS int) -- This will automatically set EmpID to the value in SESSION_CONTEXT
);

go

--Sample Data

Insert into customer(Name,City, Status,Empid ) values('Alex','London','Active',1)
Insert into customer(Name,City, Status,Empid) values('Dirk','Slough','Active',2)
Insert into customer(Name,City, Status,Empid) values('Mark','Slough','Inactive',1) 
GO

CREATE FUNCTION dbo.CustomerAccesspredicate(@EmpID int)
	RETURNS TABLE
	WITH SCHEMABINDING
AS
	RETURN SELECT 1 AS accessResult
	WHERE CAST(SESSION_CONTEXT(N'EmpID') AS int) = @EmpID
GO

CREATE SECURITY POLICY dbo.CustomerSecurityPolicy
	ADD FILTER PREDICATE dbo.CustomerAccesspredicate(Empid) ON dbo.Customer
	--,ADD BLOCK PREDICATE dbo.CustomerAccesspredicate(Empid) ON dbo.Customer AFTER INSERT 
GO

CREATE USER Apps WITHOUT LOGIN 
Go

GRANT SELECT, INSERT, UPDATE, DELETE ON Customer TO Apps

Execute as user ='APPS'
SELECT *   FROM [dbo].[CUSTOMER]
GO


Execute as User='APPS'

exec sp_set_session_context N'EmpID', 1
select * from customer

exec sp_set_session_context N'EmpID', 2
select * from customer


Execute as user ='APPS'
EXEC sp_set_session_context N'EmpID', 1
Insert into customer(Name,City, Status,Empid ) values('Adam','york','Inactive',1)  --Output 1 Row(s) inserted


Execute as user ='APPS'
EXEC sp_set_session_context N'EmpID', 1
Insert into customer(Name,City, Status,Empid ) values('SIRK','BRACK','active',2)

--und nun 
ALTER SECURITY POLICY dbo.CustomerSecurityPolicy
	--add FILTER PREDICATE dbo.CustomerAccesspredicate(Empid) ON dbo.Customer,
	ADD BLOCK PREDICATE dbo.CustomerAccesspredicate(Empid) ON dbo.Customer AFTER INSERT 
GO

Execute as user ='APPS'
EXEC sp_set_session_context N'EmpID', 1
Insert into customer(Name,City, Status,Empid ) values('SIRK','BRACK','active',2)



