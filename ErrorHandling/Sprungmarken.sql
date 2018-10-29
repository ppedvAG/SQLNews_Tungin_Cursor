--Spungmarken

--Innerhalb des Codes springen

--Spungmarke definieren:

sprungmarke:

--zu einer marke springen..
--never endig Story

GOTO sprungmarke

--DEMO
Erster:
	print'huhu'

GOTO HELL

hell:
Goto erster

--DEMO2: variablen bleiben erhalten!

declare @i as int=0
Erster:
set @i=@i+1

Goto dritter

hell:
set @i=@i+1

dritter:
select @i
goto hell






