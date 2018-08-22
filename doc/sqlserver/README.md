# Table of Contents

* [1 SqlServer 列与逗号分隔字符串 互相转换](#1-sqlserver-列与逗号分隔字符串-互相转换)
  * [1.1 编写一个表值函数，传入一个字符串，实现转换成列，条件以逗号分隔(任何符号都可以自定义)](#11-编写一个表值函数，传入一个字符串，实现转换成列，条件以逗号分隔任何符号都可以自定义)
  * [1.2 通过for XML Path实现将列转换成逗号连接的字符串](#12-通过for-xml-path实现将列转换成逗号连接的字符串)
* [2 查看sqlserver被锁的表以及如何解锁](#2-查看sqlserver被锁的表以及如何解锁)
  * [2.1 检索死锁进程](#21-检索死锁进程)
  * [2.2 查看被锁表](#22-查看被锁表)
  * [2.3 解锁](#23-解锁)


# 1 SqlServer 列与逗号分隔字符串 互相转换

在项目中，使用SQLServer数据库，有一个需求，需要将数据库的某一列，转换成逗号分隔的字符串。同时，需要将处理完的字符串，转换成为一列。
经过查阅资料与学习，通过以下方式可以实现如上所述需求：

## 1.1 编写一个表值函数，传入一个字符串，实现转换成列，条件以逗号分隔(任何符号都可以自定义)
```
--该函数把传递过来的字符串转换成IN 后面的列表，可以处理以分号，逗号以及空格分隔的字符串  
CREATE FUNCTION [dbo].[GetInStr]   
             (@SourceStr varchar(2000))--源字符串  
  
RETURNS  @table table(list  varchar(50) )    
  AS    
BEGIN  
  
--  select @sourcestr =  replace(@sourcestr,';',',')      
--  select @sourcestr = replace(@sourcestr,' ',',')  
 --declare @OutStr varchar(200)    
   if charindex(',',@sourcestr)>0    
    begin  
      declare @i int  
      declare @n int  
      set @i=1  
      while charindex(',',@sourcestr,@i)>0  
        begin  
           set @n=charindex(',',@sourcestr,@i)  
           insert into @table values(substring(@sourcestr,@i, @n-@i) )  
           set @i=@n+1  
        end  
        insert into @table values(substring(@sourcestr,@i,len(@sourcestr)-@i+1))  
    end  else insert into @table values(@sourcestr)  
  
  delete from @table where isnull(list,'') = ''  
return  
END  
```
## 1.2 通过for XML Path实现将列转换成逗号连接的字符串

```
SELECT STUFF((SELECT ','+字段名 FROM 表名 for xml path('')),1,1,'')
```
STUFF函数的意义是去掉组成字符串的尾数逗号。

# 2 查看sqlserver被锁的表以及如何解锁

## 2.1 检索死锁进程
```
--检索死锁进程  
select spid, blocked, loginame, last_batch, status, cmd, hostname, program_name  
from sysprocesses  
where spid in  
( select blocked from sysprocesses where blocked <> 0 ) or (blocked <>0)  
```

## 2.2 查看被锁表

```
select   request_session_id   spid,OBJECT_NAME(resource_associated_entity_id) tableName   
from   sys.dm_tran_locks where resource_type='OBJECT'
spid   锁表进程 
tableName   被锁表名
```
## 2.3 解锁
```
declare @spid  int 
Set @spid  = 57 --锁表进程
declare @sql varchar(1000)
set @sql='kill '+cast(@spid  as varchar)
exec(@sql)
```
