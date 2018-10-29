use tuning;
-- Testtabelle erzeugen. Die dritte Spalte
-- soll hier nur simulieren, dass noch mehr Spalten
-- vorhanden sind.
if (object_id('T1') is not null)
  drop table t1
go

--###### HEAP #######

create table T1
 (
   Id int not null
  ,Nr int not null
  ,Platzhalter nchar(400) null default '#'
 )
go
-- Füge 200.000 Zeilen ein
insert T1 (Id,Nr)
  select n, n % 100 from Numbers
   where n <= 200000
go



-- Anzeige der Indexebenen
--Ebenen selten mehr als 4.. Optimierung erst wenn weniger Ebenen

select index_id,index_type_desc,index_depth
      ,index_level,page_count,record_count
  from sys.dm_db_index_physical_stats(db_id(),object_id('T1')
                                     ,null,null,'detailed')
go


-- Anlegen von Indizes
create [unique] non clustered Index indexname on Tabelle (spalten) include (Spalten) where Filter = ()
create clustered index Indexanem on Tabelle (Spalten) 

--Indizierte Sicht!:
--muss with schemabinding, unique, clustered, kein Outer Join, bei Aggregaten Count_big(*) aufweisen
-- wird nur von Ent/Dev beachtet. Alle anderen Editione müssen (NOEXPAND) auifweisen

select Nr,count(*) as Anzahl
  from T1
  group by Nr
go



create view V1 with schemabinding as
   select Nr,count_big(*) as anz
     from dbo.T1
    group by Nr
go 

create unique clustered index Ix_V1_Nr on V1 (Nr)
go
select * from V1
go
select * from V1 with (noexpand)
go
select Nr,count(*)
  from T1
  group by Nr


