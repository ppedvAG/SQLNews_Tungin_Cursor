

CREATE TABLE EmployeeContracts AS FILETABLE
  WITH
  (
    FILETABLE_DIRECTORY = 'Arbeitsverträge'
  ) 
GO

select * from employeeContracts
