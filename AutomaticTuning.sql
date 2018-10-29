--WorldWideImportes

use   WideWorldImporters;
GO

ALTER DATABASE CURRENT SET QUERY_STORE = ON;


--Query Store aktivieren
ALTER DATABASE CURRENT SET QUERY_STORE = ON;
GO
ALTER DATABASE CURRENT SET QUERY_STORE 
(
  OPERATION_MODE = READ_WRITE,
  DATA_FLUSH_INTERVAL_SECONDS = 600,
  MAX_STORAGE_SIZE_MB = 500,
  INTERVAL_LENGTH_MINUTES = 30
  );
GO

--PROCCACHE leeren
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;

--QueryStore leeren
ALTER DATABASE CURRENT SET QUERY_STORE CLEAR ALL;

--Automatic Tuning aktivieren
ALTER DATABASE CURRENT
SET AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = ON ); 


--wirklich
SELECT * FROM sys.database_automatic_tuning_options 


--DEMO
EXEC sp_executesql N'select sum([UnitPrice]*[Quantity])
						from Sales.OrderLines SL inner join sales.orders SO on SL.OrderID=SO.OrderID
						where PackageTypeID = @ptid', N'@ptid int',
					@ptid = 7;
GO 600

--TOP Consuming Queries


--nun
--neuen Plan errechnen lassen
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;

EXEC sp_executesql N'select sum([UnitPrice]*[Quantity])
						from Sales.OrderLines SL inner join sales.orders SO on SL.OrderID=SO.OrderID
						where PackageTypeID = @ptid', N'@ptid int',
					@ptid = 0;
GO 


--Neuer Plan


--QueryStore

EXEC sp_executesql N'select sum([UnitPrice]*[Quantity])
						from Sales.OrderLines SL inner join sales.orders SO on SL.OrderID=SO.OrderID
						where PackageTypeID = @ptid', N'@ptid int',
					@ptid = 7;
GO 20



GO

--??
SELECT 
	reason, 
	score,
	JSON_VALUE(state, '$.currentValue') state,
	JSON_VALUE(state, '$.reason') state_transition_reason,
    script = JSON_VALUE(details, '$.implementationDetails.script'),
	[current plan_id],
	[recommended plan_id],
	is_revertable_action,
	never_estimated_gain = (regressedPlanExecutionCount+recommendedPlanExecutionCount)
                  *(regressedPlanCpuTimeAverage-recommendedPlanCpuTimeAverage)/1000000
    FROM sys.dm_db_tuning_recommendations
	CROSS APPLY OPENJSON (Details, '$.planForceDetails')
    WITH (  [query_id] int '$.queryId',
            [current plan_id] int '$.regressedPlanId',
            [recommended plan_id] int '$.recommendedPlanId',
            regressedPlanExecutionCount int,
            regressedPlanCpuTimeAverage float,
            recommendedPlanExecutionCount int,
            recommendedPlanCpuTimeAverage float
          ) as planForceDetails;
;

--IX Vorschlag

CREATE NONCLUSTERED INDEX [NCI_SalesOrderLines_PTID]
ON [dbo].[SalesOrderLines] ([OrderID],[PackageTypeID])
INCLUDE ([Quantity],[UnitPrice])