# database-example
工作过程遇到的，或者平时学习的数据库相关的知识点汇总

# 1. oracle 大数据量加载方法汇总

## 1.1 数据载入方法
在 Oracle 数据库中，我们通常在不同数据库的表间记录进行复制或迁移时会用以下几种方法：
1. A 表的记录导出为一条条分号隔开的 insert 语句，然后执行插入到 B 表中
2. 建立数据库间的 dblink，然后用 create table B as select * from A@dblink where ...，或 insert into B select * from A@dblink where ...
3. exp A 表，再 imp 到 B 表，exp 时可加查询条件
4. 程序实现 select from A ..，然后 insert into B ...，也要分批提交
5. 再就是本篇要说到的 Sql Loader(sqlldr) 来导入数据，效果比起逐条 insert 来很明显

第 1 种方法在记录多时是个噩梦，需三五百条的分批提交，否则客户端会死掉，而且导入过程很慢。如果要不产生 REDO 来提高 insert into 的性能，就要下面那样做：

```
alter table B nologging;
insert /* +APPEND */ into B(c1,c2) values(x,xx);
insert /* +APPEND */ into B select * from A@dblink where .....;
```

## 1.2 Oracle的Sql Loader (sqlldr) 的用法
在命令行下执行 Oracle  的 sqlldr 命令，可以看到它的详细参数说明，要着重关注以下几个参数：

```
userid -- Oracle 的 username/password[@servicename]
control -- 控制文件，可能包含表的数据
-------------------------------------------------------------------------------------------------------
log -- 记录导入时的日志文件，默认为 控制文件(去除扩展名).log
bad -- 坏数据文件，默认为 控制文件(去除扩展名).bad
data -- 数据文件，一般在控制文件中指定。用参数控制文件中不指定数据文件更适于自动操作
errors -- 允许的错误记录数，可以用他来控制一条记录都不能错
rows -- 多少条记录提交一次，默认为 64
skip -- 跳过的行数，比如导出的数据文件前面几行是表头或其他描述
```

还有更多的 sqlldr 的参数说明请参考：sql loader的用法。http://psoug.org/reference/sqlloader.html

## 1.3 sql Loader示例
具体sql loader的示例代码在sqlloader目录下。

执行命令：sqlldr dbuser/dbpass@dbservice control=update_data.ctl

注意：sqlldr为系统命令，在pl/sql下是不能执行的，需要在操作系统中执行（linux下），sql plus不知道行不行。

参考链接： https://www.cnblogs.com/flish/archive/2010/05/31/1748221.html


# 2 Oracle大数据量更新方法

第一节介绍了大数据量的导入方法，这边介绍一下，大数据量如何批量更新的问题。

## 2.1 关联更新

```
UPDATE (SELECT \*+ BYPASS_UJVC *\
         T1.SEND_EMAIL, T3.EMAIL_STATUS_USER
          FROM USER_PROFILE                      T1,
               EMAIL_APP_LEAD    T2,
               EMAIL_FLAG_STATUS T3
         WHERE T1.USER_PROFILE_ID = T2.USER_PROFILE_ID
           AND T2.EMAIL_FLAG = T3.EMAIL_FLAG
           AND T2.USER_PROFILE_ID IS NOT NULL) R
   SET R.SEND_EMAIL = R.EMAIL_STATUS_USER;
```

此种方法耗时比较久,并且使用这种方式来更新表，需要用于更新的表(最终数据表)的关联字段必须设置为主键，且不可多字段主键。

## 2.2 加入并行度，hash，并且加入rowid排序

```
DECLARE
  MAX_ROWS NUMBER DEFAULT 10000;

  --APP
  ROW_ID_TABLE_APP     DBMS_SQL.UROWID_TABLE;
  EMAIL_FLAG_TABLE_APP DBMS_SQL.VARCHAR2_TABLE;
  -- APP CURSOR
  CURSOR EMAIL_APP_CUR IS
    SELECT /*+ use_hash(t1,t2) parallel(t1,4) parallel(t2,4) */
     T3.EMAIL_STATUS_USER, T1.ROWID
      FROM USER_PROFILE                      T1,
           EMAIL_APP_LEAD    T2,
           EMAIL_FLAG_STATUS T3
     WHERE T1.USER_PROFILE_ID = T2.USER_PROFILE_ID
       AND T2.EMAIL_FLAG = T3.EMAIL_FLAG
       AND T2.USER_PROFILE_ID IS NOT NULL
     ORDER BY T1.ROWID;
BEGIN

  --UPDATE USER_PROFILE FROM APP
  OPEN EMAIL_APP_CUR;
  LOOP
    EXIT WHEN EMAIL_APP_CUR%NOTFOUND;
    FETCH EMAIL_APP_CUR BULK COLLECT
      INTO EMAIL_FLAG_TABLE_APP, ROW_ID_TABLE_APP LIMIT MAX_ROWS;
    FORALL I IN 1 .. ROW_ID_TABLE_APP.COUNT
      UPDATE USER_PROFILE
         SET SEND_EMAIL = EMAIL_FLAG_TABLE_APP(I),UPDATED_BY = 'BKOF-7959-Webbula',UPDATED_WHEN=SYSDATE
       WHERE ROWID = ROW_ID_TABLE_APP(I);
    COMMIT;
  END LOOP;

END;
```

具体代码示例参考目录bigdata_update

## 2.3 参考链接：
1. http://blog.csdn.net/leinuo180/article/details/23344647
2. http://blog.sina.com.cn/s/blog_69e9f7cd0100nm2t.html

# 3 oracle中去掉回车换行空格的方法

```
UPDATE EMAIL_APP_LEAD t2 SET t2.email_flag = replace(t2.email_flag,to_char(chr(13)),''); --换行
UPDATE EMAIL_APP_LEAD t2 SET t2.email_flag = replace(t2.email_flag,to_char(chr(10)),''); --回车
UPDATE EMAIL_APP_LEAD t2 SET t2.email_flag = trim(t2.email_flag); --空格
```

# 4.v$parameter, v$parameter2, v$system_parameter, v$system_parameter2, v$spparameter区别

## 4.1 概念
1. v$parameter
    v$parameter显示的是session级的参数. 如果没有使用alter session单独设置当前session的参数值.
    每一个新Session都是从 v$system_parameter上取得系统的当前值而产生Session的v$parameter view. (实验1)
    在运行过程中, v$parameter可能被用户改变.
2. v$parameter2
    v$parameter2显示的是session级的参数.
    与v$parameter之间的区别则在于v$parameter2把LIST的值分开来了, 一行变多行数据, 用ORDINAL来指示相对的位置. (实验2)
3. v$system_parameter
    v$system_parameter显示的是system级的参数, 保存的是使用alter system修改的值(scope=both或者memory). 上面两个都是当前已经生效的参数值.
4. v$system_parameter2
    v$system_parameter2显示的是system级的参数.
5. v$spparameter
    v$spparameter显示的就是保存在spfile中的参数值(scope=both或者spfile).

## 4.2 show parameter（SQL 命令）
通过sql_trace发现，sqlplus中的show parameter其实查询的是v$parameter，实际的查询语句如下：
```
SELECT NAME NAME_COL_PLUS_SHOW_PARAM,
       DECODE(TYPE,
       
              1,
              
              'boolean',
              
              2,
              
              'string',
              
              3,
              
              'integer',
              
              4,
              
              'file',
              
              5,
              
              'number',
              
              6,
              
              'big integer',
              
              'unknown') TYPE,
       
       DISPLAY_VALUE VALUE_COL_PLUS_SHOW_PARAM

  FROM V$PARAMETER

 WHERE UPPER(NAME) LIKE UPPER('%db_file%')

 ORDER BY NAME_COL_PLUS_SHOW_PARAM, ROWNUM;

 ```
 ## 4.3 底层表解释
 通过autotrace，可以知道：
 1. v$parameter,v$system_parameter的底层表是x$ksppcv和x$ksppi
 2. v$parameter2,v$system_parameter2的底层表是x$ksppcv2和x$ksppi
 3. v$spparameter的底层表是x$kspspfile
 ## 4.4 参考链接
 案例：见GET_DATABASE_NAME.sql
 
 http://blog.csdn.net/huang_xw/article/details/6173891

 # 5 oracle 的dbms_application_info包

 dbms_application_info提供了通过v$session跟踪脚本运行情况的能力，该包允许我们在v$session设置如下三个列的值：
 client_info,module,action
 还提供了返回这三列的值.dbms_application_info和v$session相关的函数；
     1. dbms_application_info.set_client_info:一般情况下该列填写客户点的信息，但是也可以根据自己的需要填写自己想要的信息
     2. dbms_application_info.set_module:根据自己的需要填写自己想要的信息
     3. dbms_application_info.read_client_info和dbms_application_info.read_module读取这三列的信息

 案例参见：sqlscripts/dbmsApplicationInfoPkgDemo.sql

 
