SELECT     Customers.CompanyName, Customers.CustomerID, Customers.City, Customers.Country, Orders.OrderID, Orders.OrderDate, Orders.Freight, Orders.ShipCity, Orders.ShipCountry, [Order Details].UnitPrice, [Order Details].Quantity, [Order Details].ProductID, 
                  Products.ProductName, Employees.EmployeeID, Employees.LastName, Employees.FirstName, Employees.City AS Expr1, Employees.Country AS Expr2
INTO umsatzxy
FROM        Customers INNER JOIN
                  Orders ON Customers.CustomerID = Orders.CustomerID INNER JOIN
                  [Order Details] ON Orders.OrderID = [Order Details].OrderID INNER JOIN
                  Products ON [Order Details].ProductID = Products.ProductID INNER JOIN
                  Employees ON Orders.EmployeeID = Employees.EmployeeID
go

insert into umsatzxy
select * from umsatzxy
GO

alter table umsatzxy
add UmsatzID int identity
GO

select top 5 * from umsatzxy

--ColumnStore

--ca 570MB mit ca. 2,2 Mio Zeilen

--Kopie
select * into Umsatzxy2 from umsatzxy


USE [Northwind]
GO

/****** Object:  Index [GRCSIX]    Script Date: 04.08.2016 14:27:21 ******/
CREATE CLUSTERED COLUMNSTORE INDEX
 [GRCSIX] ON [dbo].[umsatzxy]
  WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [PRIMARY]
GO
--Die Kopie mit Zeilendaten hätte bei Kompression ca 170MB

--Die CS Tabelle hat nur nch 7 MB ca

USE [Northwind]
ALTER TABLE [dbo].[umsatzxy] REBUILD PARTITION = ALL
WITH 
(DATA_COMPRESSION = COLUMNSTORE_ARCHIVE
)

--nach Archivierungskompression ca 6,8
--Messung der CPU, Dauer und HDD Zugriff
set statistics io on
set statistics time on


select top 3 * from umsatzxy

select country, sum(freight) from umsatzxy
where country ='Germany'
group by country


select country, sum(freight) from umsatzxy2
where country ='Germany'
group by country
--70195 Lesen
--CPU-Zeit = 938 ms, verstrichene Zeit = 249 ms.





