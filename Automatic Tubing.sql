--Abfragespeicher aktivieren

use nwindBig

ALTER DATABASE current
SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = ON ); 


SELECT name, actual_state_desc, status = IIF(desired_state_desc <> actual_state_desc, reason_desc, 'Status:OK')
FROM sys.database_automatic_tuning_options
WHERE name = 'FORCE_LAST_GOOD_PLAN';



SELECT reason, score,
       JSON_VALUE(state, '$.currentValue') state,
       JSON_VALUE(state, '$.reason') state_transition_reason,
       JSON_VALUE(details, '$.implementationDetails.script') script,
       planForceDetails.*
FROM sys.dm_db_tuning_recommendations
  CROSS APPLY OPENJSON (Details, '$.planForceDetails')
    WITH (  [query_id] int '$.queryId',
            [new plan_id] int '$.regressedPlanId',
            [recommended plan_id] int '$.recommendedPlanId'
          ) as planForceDetails;







SELECT reason, score,
      script = JSON_VALUE(details, '$.implementationDetails.script'),
      planForceDetails.*,
      estimated_gain = (regressedPlanExecutionCount+recommendedPlanExecutionCount)
                  *(regressedPlanCpuTimeAverage-recommendedPlanCpuTimeAverage)/1000000,
      error_prone = IIF(regressedPlanErrorCount>recommendedPlanErrorCount, 'YES','NO')
--INTO DBA.Compare.Tunning_Recommendations
FROM sys.dm_db_tuning_recommendations
  CROSS APPLY OPENJSON (Details, '$.planForceDetails')
    WITH (  [query_id] int '$.queryId',
            [current plan_id] int '$.regressedPlanId',
            [recommended plan_id] int '$.recommendedPlanId',

            regressedPlanErrorCount int,
            recommendedPlanErrorCount int,

            regressedPlanExecutionCount int,
            regressedPlanCpuTimeAverage float,
            recommendedPlanExecutionCount int,
            recommendedPlanCpuTimeAverage float

          ) as planForceDetails;

---DemoTabelle
select * into C2 from Customers	   ;

create nonclustered Index NIX1 on c2 (Customerid)		 ;



CREATE OR ALTER procedure gpsuche @id as varchar(5)
as
select * from c2 where customerid like  @id	;
GO

-- fdeaw


select * from c2 where customerid like  'fdeaw'
select * from c2 where customerid like   'f%'

exec gpsuche 'fdeaw'

exec gpsuche 'f%'
