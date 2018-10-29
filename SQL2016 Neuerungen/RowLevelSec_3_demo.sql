DROP Table Sales2
GO

CREATE TABLE Sales2 (  
    OrderId int,  
    AppUserId int,  
    Product varchar(10),  
    Qty int  
);  
GO


INSERT Sales2 VALUES   
    (1, 1, 'Valve', 5),   
    (2, 1, 'Wheel', 2),   
    (3, 1, 'Valve', 4),  
    (4, 2, 'Bracket', 2),   
    (5, 2, 'Wheel', 5),   
    (6, 2, 'Seat', 5);  
GO

--CREATE SCHEMA Security;  
--GO  
  
CREATE FUNCTION Security.fn_securitypredicate2(@AppUserId int)  
    RETURNS TABLE  
    WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS fn_securitypredicate_result  
    WHERE  
        DATABASE_PRINCIPAL_ID() = DATABASE_PRINCIPAL_ID('AppUser')    
        AND CAST(SESSION_CONTEXT(N'UserId') AS int) = @AppUserId;   
GO  

CREATE SECURITY POLICY Security.SalesFilter2  
    ADD FILTER PREDICATE Security.fn_securitypredicate2(AppUserId)   
        ON dbo.Sales2,  
    ADD BLOCK PREDICATE Security.fn_securitypredicate2(AppUserId)   
        ON dbo.Sales2 AFTER INSERT   
    WITH (STATE = ON); 



	-- Without login only for demo  
CREATE USER AppUser WITHOUT LOGIN;   
GRANT SELECT, INSERT, UPDATE, DELETE ON Sales TO AppUser;  
  
-- Never allow updates on this column  
DENY UPDATE ON Sales2(AppUserId) TO AppUser;  
GO

EXECUTE AS USER = 'AppUser';  
EXEC sp_set_session_context @key=N'UserId', @value=1;  
SELECT * FROM Sales2;  
GO  
  
--  Note: @read_only prevents the value from changing again   
--  until the connection is closed (returned to the connection pool)  
EXEC sp_set_session_context @key=N'UserId', @value=2, @read_only=1;   
  
SELECT * FROM Sales2;  
GO  
  
INSERT INTO Sales2 VALUES (7, 1, 'Seat', 12); -- error: blocked from inserting row for the wrong user ID  
GO  
  
REVERT;  
GO  