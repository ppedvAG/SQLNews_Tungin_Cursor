create user Chef without login
create user AbtLeiter without Login
create user Manager without Login


CREATE TABLE [dbo].[Employees]
(
  [ID] [int] PRIMARY KEY CLUSTERED IDENTITY(1,1) NOT NULL,
  [Name] [varchar](100) NULL,
  [Address] [varchar](256) NULL,
  [Email] [varchar](256) NULL,
  [Salary] [decimal](18,2) NOT NULL,
  [SecColFilter] [varchar](128) NULL
);


-- Funktion für Sicherheitsfilter erstellen
CREATE FUNCTION dbo.fn_hasAccess(@RoleOrUsername AS sysname)
    RETURNS TABLE
    WITH SCHEMABINDING -- Muss angegeben werden
AS
RETURN
(
  SELECT 1 'Granted' WHERE 
    USER_NAME() = @RoleOrUsername OR IS_MEMBER(ISNULL(@RoleOrUsername, 'PUBLIC')) = 1
);
GO


CREATE SECURITY POLICY SecretFilter
ADD FILTER PREDICATE dbo.fn_hasAccess([SecColFilter]) ON [dbo].[Employees],
ADD BLOCK PREDICATE dbo.fn_hasAccess([SecColFilter]) ON [dbo].[Employees] AFTER INSERT,
ADD BLOCK PREDICATE dbo.fn_hasAccess([SecColFilter]) ON [dbo].[Employees] BEFORE DELETE,
ADD BLOCK PREDICATE dbo.fn_hasAccess([SecColFilter]) ON [dbo].[Employees] BEFORE UPDATE;
-- Weitere Filter/Blockprädikate für weitere Tabelle

GRANT SELECT, INSERT, DELETE, UPDATE ON [dbo].[Employees] TO PUBLIC;

-- Securtiy Policy aktivieren
ALTER SECURITY POLICY [dbo].[SecretFilter] WITH (STATE = ON);
-- Securtiy Policy deaktivieren
ALTER SECURITY POLICY [dbo].[SecretFilter] WITH (STATE = OFF);


ALTER TABLE [dbo].[Employees]
ALTER COLUMN [Name] ADD MASKED WITH (FUNCTION = 'partial(1,"-",2)');
ALTER TABLE [dbo].[Employees]
ALTER COLUMN [Address] ADD MASKED WITH (FUNCTION = 'default()');
ALTER TABLE [dbo].[Employees]
ALTER COLUMN [Email] ADD MASKED WITH (FUNCTION = 'email()');
ALTER TABLE [dbo].[Employees]
ALTER COLUMN [Salary] ADD MASKED WITH (FUNCTION = 'random(1, 1999)');

execute as user='Manager'
select * from employees

select session_Context()

ALTER TABLE [dbo].[Employees] ADD Mandator VARCHAR(10) NULL;
GO
 
CREATE VIEW [dbo].[vwEmployees] AS
SELECT * FROM [dbo].[Employees] 
WHERE Mandator IS NULL OR 
      Mandator = SESSION_CONTEXT(N'MandatorKey');


EXEC sp_set_session_context @key = 'MandatorKey', @value = 'MK03';
GO
SELECT * FROM dbo.vwEmployees;

;
