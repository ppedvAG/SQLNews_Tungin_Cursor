Use AdventureWorks2014;
GO


--lesbare Kreditkartendaten 
select top 5 * from sales.creditCard

Drop Table If Exists sales.creditcardEnc;

Select * into sales.creditcardenc from sales.creditcard;
GO

--assi auf Tabelle...

select * from sales.CreditcardEnc

--nur wieder per SSMS :   Column Encryption Setting = Enabled