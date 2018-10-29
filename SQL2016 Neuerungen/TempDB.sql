--TRACEFLAG: Trace Flag 1118 – Full Extents Only

--Trace Flag 1117 – Grow All Files in a FileGroup Equally

select name,is_mixed_page_allocation_on
 from sys.databases where database_id in( 1,2,3,4)



EXEC SP_MSFOREACHDB @command1='use ?; select db_name() as DBName, is_autogrow_all_files from sys.filegroups'