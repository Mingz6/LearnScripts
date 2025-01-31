DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @keyword NVARCHAR(255) = 'Keyword';

SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE '%'+@keyword+'%';

-- Construct dynamic SQL for each table and column
SELECT @sql += 
    'SELECT ''' + TABLE_SCHEMA + ''' AS TableSchema, ''' + 
    TABLE_NAME + ''' AS TableName, ''' + 
    COLUMN_NAME + ''' AS ColumnName, ' + 
    'CAST([' + COLUMN_NAME + '] AS NVARCHAR(MAX)) AS Value ' +
    'FROM [' + TABLE_SCHEMA + '].[' + TABLE_NAME + '] ' +
    'WHERE CAST([' + COLUMN_NAME + '] AS NVARCHAR(MAX)) LIKE ''%' + @keyword + '%'' UNION ALL '
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE IN ('char', 'nchar', 'varchar', 'nvarchar', 'text', 'ntext');

-- Remove the last UNION ALL
SET @sql = LEFT(@sql, LEN(@sql) - 10);

-- Execute the dynamic SQL
EXEC sp_executesql @sql;
