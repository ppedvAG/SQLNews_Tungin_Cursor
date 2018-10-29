RAISERROR (N'<<%*.*s>>', -- Message text.  
           10, -- Severity,  
           1, -- State,  
           7, -- First argument used for width.  
           3, -- Second argument used for precision.  
           N'abcde'); -- Third argument supplies the string.  
-- The message text returned is: <<    abc>>.  
GO  
RAISERROR (N'<<%-7.3s>>', -- Message text.  
           10, -- Severity,  
           1, -- State,  
           N'abcde'); -- First argument supplies the string.  
-- The message text returned is: <<    abc>>.  
GO  


--Eigene Fehlernummern definieren
--sp_addmessage

RAISERROR (N'This is message %0s %o.', -- Message text in oktal  
           10, -- Severity,  
           1, -- State,  
           N'number', -- First argument.  
           5000); -- Second argument.  
-- The message text returned is: This is message number 5.  
GO  

