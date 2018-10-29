ALTER DATABASE [queryStore] SET QUERY_STORE CLEAR ALL 


use master
GO

create Database queryStore
GO

-- Enable the Query Store for our database
ALTER DATABASE QueryStore
SET QUERY_STORE = ON
GO
 
-- Configure the Query Store
ALTER DATABASE QueryStore SET QUERY_STORE
(
	OPERATION_MODE = READ_WRITE, 
	CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 367), 
	DATA_FLUSH_INTERVAL_SECONDS = 900, 
	INTERVAL_LENGTH_MINUTES = 1, 
	MAX_STORAGE_SIZE_MB = 100, 
	QUERY_CAPTURE_MODE = ALL, 
	SIZE_BASED_CLEANUP_MODE = OFF
)
GO

--Neue Tabelle
CREATE TABLE Customers
(
	CustomerID INT NOT NULL PRIMARY KEY CLUSTERED,
	CustomerName CHAR(10) NOT NULL,
	CustomerAddress CHAR(10) NOT NULL,
	Comments CHAR(5) NOT NULL,
	Value INT NOT NULL
)
GO
 
-- Non-Clustered Index
CREATE UNIQUE NONCLUSTERED INDEX idx_Test ON Customers(Value)
GO
 
-- Insert 80000 records
DECLARE @i INT = 1
WHILE (@i <= 80000)
BEGIN
	INSERT INTO Customers VALUES
	(
		@i,
		CAST(@i AS CHAR(10)),
		CAST(@i AS CHAR(10)),
		CAST(@i AS CHAR(5)),
		@i
	)	
	SET @i += 1
END
GO


--Proc zur Abfrage
drop procedure RetrieveCustomers;
GO

CREATE PROCEDURE RetrieveCustomers
	(
		@Value INT
	)
AS
BEGIN
	SELECT * FROM Customers	WHERE Value < @Value
END
GO


set statistics io on


select * from Customers

EXEC RetrieveCustomers 80000

DBCC FREEPROCCACHE 

EXEC RetrieveCustomers 1
EXEC RetrieveCustomers 80000 --viele Reads




