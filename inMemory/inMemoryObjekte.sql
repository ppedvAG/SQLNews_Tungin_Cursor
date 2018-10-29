--inMemory Objekte finden


 SELECT name, object_id, type, type_desc, is_memory_optimized, durability, durability_desc
    FROM sys.tables
    WHERE is_memory_optimized=1

  SELECT object_name(object_id), object_id, definition, uses_native_compilation 
    FROM sys.sql_modules
    WHERE uses_native_compilation=1