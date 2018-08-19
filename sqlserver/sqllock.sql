select request_session_id spid,OBJECT_NAME(resource_associated_entity_id) tableName
from sys.dm_tran_locks where resource_type='OBJECT'

EXEC sp_who active

EXEC sp_lock

select * from sys.dm_tran_locks
SELECT * FROM sys.dm_exec_requests WHERE blocking_session_id<>0

select * from sys.sysprocesses

SELECT
DISTINCT 'DECLARE @spid INT SET @spid = ',request_session_id,' DECLARE @SQL VARCHAR (1000) SET @SQL = ''kill '' + CAST (@spid AS VARCHAR) EXEC (@SQL);' as s
FROM
sys.dm_tran_locks
WHERE
resource_type = 'OBJECT' --spid 锁表进程
--tableName 被锁表名

--检索死锁进程
select spid, blocked, loginame, last_batch, status, cmd, hostname, program_name
from sysprocesses
where spid in
( select blocked from sysprocesses where blocked <> 0 ) or (blocked <>0)