CREATE DATABASE imoltp;    --  Transact-SQL  
go  
  
ALTER DATABASE IMOLTP ADD FILEGROUP [imoltp_mod]  
    CONTAINS MEMORY_OPTIMIZED_DATA;  
  
ALTER DATABASE imoltp ADD FILE  
    (name = [imoltp_dir], filename= 'C:\_SQLDB\MSSQL13.MSSQLSERVER\MSSQL\DATA\imoltp_dir')  
    TO FILEGROUP imoltp_mod;  
go  
  
USE imoltp;  
go  