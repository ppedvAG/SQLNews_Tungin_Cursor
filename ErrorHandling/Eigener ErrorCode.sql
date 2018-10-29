
sp_addmessage @msgnum = 50005,  
              @severity = 10,  
              @msgtext = N'<<%7.3s>>'	   ,
			  @lang='german';
GO  

EXECUTE sp_altermessage 50005, 'WITH_LOG', 'true';  


RAISERROR (50005, -- Message id.  
           10, -- Severity,  
           1, -- State,  
           N'abcde'); -- First argument supplies the string.  
-- The message text returned is: <<    abc>>.  
GO  
sp_dropmessage @msgnum = 50005;  
GO  

select * from sys.messages