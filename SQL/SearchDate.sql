SET NOCOUNT ON;
DECLARE @FindText NVARCHAR(MAX) = 'Prosecution';
DECLARE @cmd NVARCHAR(MAX);
DECLARE @deets NVARCHAR(MAX);
DECLARE @Params NVARCHAR(MAX);
DECLARE @Name VARCHAR(1000);
DECLARE @Count INT;
DECLARE @RowNum INT;
SET @RowNum = 0;
SET @cmd = '';
SET @deets = '';
SET @Params = '@Name VARCHAR(1000) OUTPUT, @Count INT OUTPUT';

DECLARE cur CURSOR LOCAL FORWARD_ONLY STATIC
FOR
SELECT 'SELECT @Name = ''' + s.name + '.' + o.name + '.' + c.name + ''', @Count = COUNT(1) FROM ' + QUOTENAME(s.name) + '.' + QUOTENAME(o.name) + ' c WHERE ' + QUOTENAME(c.name) + ' = ' + @FindText + ' HAVING COUNT(1) > 0;'
    , 'SELECT * FROM ' + s.name + '.' + o.name + ' WHERE ' + QUOTENAME(c.name) + ' = ' + @FindText + ';'
FROM sys.schemas s WITH (NOLOCK)
    INNER JOIN sys.objects o WITH (NOLOCK) ON s.schema_id = o.schema_id
    INNER JOIN sys.columns c WITH (NOLOCK) ON o.object_id = c.object_id
    INNER JOIN sys.types t ON c.system_type_id = t.system_type_id
WHERE o.is_ms_shipped = 0
    AND o.type_desc = N'USER_TABLE'
    AND s.name <> N'sys' --ignore the sys schema
    AND t.name IN ( --could eliminate all but datetime if certain!
        'date'
        , 'datetime2'
        , 'datetimeoffset'
        , 'smalldatetime'
        , 'datetime'
    );

OPEN cur;
FETCH NEXT FROM cur INTO @cmd, @deets;
WHILE @@FETCH_STATUS = 0
BEGIN
    --PRINT N'RowNum:' + CONVERT(VARCHAR(50), @RowNum);
    SET @Name = NULL;
    SET @Count = NULL;
    EXEC sp_executesql @cmd, @Params, @Name = @Name OUT, @Count = @Count OUT;
    IF @Count > 0 PRINT @Name + ': ' + CONVERT(VARCHAR(50), @Count) + '                            ' + @deets;
    SET @RowNum = @RowNum + 1;
    FETCH NEXT FROM cur INTO @cmd, @deets;
END
CLOSE cur;
DEALLOCATE cur;