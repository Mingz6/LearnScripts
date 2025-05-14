SELECT 
    CAST((SUM(reserved_page_count) * 8192.0) / 1024 / 1024 / 1024 AS DECIMAL(10, 2)) AS DbSizeInGB
FROM 
    sys.dm_db_partition_stats;


EXEC sp_helpfile;

-- 將資料庫切換到 SIMPLE 模式
ALTER DATABASE ECDB_DevLocal SET RECOVERY SIMPLE;

-- 強制釋放未使用的日誌空間，縮小到 128MB（或你希望的大小）
DBCC SHRINKFILE (ECDB_DevLocal_log, 128);

-- 查詢目前檔案空間狀況（看看有多少空間可釋放）
SELECT
    name AS FileName,
    size * 8 / 1024 AS SizeMB,
    size * 8.0 / 1024 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) * 8.0 / 1024 AS FreeSpaceMB
FROM sys.database_files;