use msdb
SELECT sj.Name, 
    CASE
        WHEN sja.start_execution_date IS NULL THEN 'Not running'
        WHEN sja.start_execution_date IS NOT NULL AND sja.stop_execution_date IS NULL THEN 'Running'
        WHEN sja.start_execution_date IS NOT NULL AND sja.stop_execution_date IS NOT NULL THEN 'Not running'
    END AS 'RunStatus'
FROM msdb.dbo.sysjobs sj (nolock)
JOIN msdb.dbo.sysjobactivity sja (nolock)
ON sj.job_id = sja.job_id 
WHERE 
session_id = (SELECT MAX(session_id) FROM msdb.dbo.sysjobactivity)
and sj.name = 'PRISM_Join_To_Prism_Files'
and sja.start_execution_date IS NOT NULL AND sja.stop_execution_date IS NOT NULL; 