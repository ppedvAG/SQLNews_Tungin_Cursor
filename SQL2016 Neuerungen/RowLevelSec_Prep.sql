Create Database RowLevel
GO

USe RowLevel
GO

Create table dbo.Orders
(
Supplier_Code int,
[Supplier_name] varchar(10),
[Orderdate] datetime,
[OrderQuantity] int,
[ProcessedBy] Varchar(10)
)      
     
 
 -- Sample data
Insert into dbo.orders values(101,'AXP Inc',convert(datetime,'2015-08-11 00:34:51:090',101),1789,'LAX')
Insert into dbo.orders values(102,'VFG Inc',convert(datetime,'2014-01-08 19:44:51:090',101),767,'AURA')
Insert into dbo.orders values(103,'ZAD Inc',convert(datetime,'2015-08-19 19:44:51:090',101),500,'ZAP')
Insert into dbo.orders values(102,'VFG Inc',convert(datetime,'2014-08-19 19:44:51:090',101),1099,'ZAP')
Insert into dbo.orders values(101,'AXP Inc',convert(datetime,'2014-08-04 19:44:51:090',101),654,'LAX')
Insert into dbo.orders values(103,'ZAD Inc',convert(datetime,'2015-08-10 19:44:51:090',101),498,'LAX')
Insert into dbo.orders values(102,'VFG Inc',convert(datetime,'2015-04-17 19:44:51:090',101),999,'LAX')
Insert into dbo.orders values(101,'AXP Inc',convert(datetime,'2015-08-21 19:44:51:090',101),543,'LAX')
Insert into dbo.orders values(103,'ZAD Inc',convert(datetime,'2015-08-06 19:44:51:090',101),876,'LAX')
Insert into dbo.orders values(102,'VFG Inc',convert(datetime,'2015-08-26 19:44:51:090',101),665,'LAX')


