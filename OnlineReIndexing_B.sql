SELECT * FROM sys.index_resumable_operations

ALTER INDEX NIX1 ON FactSales PAUSE
SELECT * FROM sys.index_resumable_operations

ALTER INDEX NIX1 ON FactSales RESUME
GO


ALTER INDEX NIX1 ON FactSales ABORT
SELECT * FROM sys.index_resumable_operations


