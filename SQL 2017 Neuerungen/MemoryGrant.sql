use AdventureworksDW2016_EXT
go
alter database AdventureworksDW2016_EXT set compatibility_level = 130;
go
select 
	CarrierTrackingNumber 
from 
	dbo.FactResellerSalesXL_CCI c 
where 
	c.DueDate between '20140101' and '20150101' 
order by 
	c.CarrierTrackingNumber, c.CustomerPONumber;
go

	  ----
update statistics dbo.FactResellerSalesXL_CCI with rowcount = 5000000 --11669600
go
select 
	CarrierTrackingNumber 
from 
	dbo.FactResellerSalesXL_CCI c 
where 
	c.DueDate between '20140101' and '20150101' 
order by 
	c.CarrierTrackingNumber, c.CustomerPONumber
option(querytraceon 9453, maxdop 1);


--GRANT MEMORY
select 
	CarrierTrackingNumber 
from 
	dbo.FactResellerSalesXL_CCI c 
where 
	c.DueDate between '20140101' and '20150101' 
order by 
	c.CarrierTrackingNumber, c.CustomerPONumber
