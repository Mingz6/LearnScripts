-- Get detailed information about all database files (data and log)
SELECT 
    DB_NAME(f.database_id) AS DatabaseName,
    f.name AS LogicalFileName,
    f.type_desc AS FileType,
    f.physical_name AS PhysicalFilePath,
    CAST(f.size * 8192.0 / 1024 / 1024 / 1024 AS DECIMAL(10,2)) AS FileSizeGB,
    CAST(f.max_size * 8192.0 / 1024 / 1024 / 1024 AS DECIMAL(10,2)) AS MaxSizeGB,
    f.growth AS GrowthSetting,
    CASE 
        WHEN f.is_percent_growth = 1 THEN 'Percent'
        ELSE 'MB'
    END AS GrowthType,
    d.recovery_model_desc AS RecoveryModel
FROM sys.master_files f
JOIN sys.databases d ON f.database_id = d.database_id
ORDER BY DB_NAME(f.database_id), f.type_desc;

-- Then shrink the log file
USE <YourDatabaseName>;  -- Replace with your database name
GO

ALTER DATABASE <YourDatabaseName> SET RECOVERY SIMPLE;
DBCC SHRINKFILE('<YourLogFileName>', 100);  -- Shrink to 100 MB

-- 查詢目前檔案空間狀況（看看有多少空間可釋放）
SELECT
    name AS FileName,
    size * 8 / 1024 AS SizeMB,
    size * 8.0 / 1024 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) * 8.0 / 1024 AS FreeSpaceMB
FROM sys.database_files;