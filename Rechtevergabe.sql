--Security: Besitzverkettung
--Hat jedes Objekt denselben Besitzer, dann 
--gelten nur die Rechte auf das aufzurufende Objekt
--zb: Sicht auf Sicht auf Sicht auf Tabelle


select * from orders --darf Eva nicht
select * from dbo.orders --darf Eva auch nicht
select * from employees --darf Eva nicht
select *from it.personal2 --darf Eva schon

--Eva hat nur LEsezugriff auf IT (Schema) OBjekte
--Der ZUgriff auf dbo.employees wurde Eva explizit verweigert
--Eva bekommt das Sichten (nur im Schema IT )erstellten zu dürfen

--auf DB :: Sicht erstellen
--auf Schema IT: ALTER Recht ( =CREATE, DROP, ALTER)

create view it.v1
as
select * from employees

select * from it.v1

--funktioniert, da it und dbo Schema derselben Person gehören (dbo)

select * from it.personal