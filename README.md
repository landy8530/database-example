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

 dbms_application_info提供了通过v$session跟踪脚本运行情况的能力，该包允许我们在v$session设置如下三个列的值：**client_info,module,action**
  
 还提供了返回这三列的值.dbms_application_info和v$session相关的函数:
 
     1.dbms_application_info.set_client_info:一般情况下该列填写客户点的信息，但是也可以根据自己的需要填写自己想要的信息。
     
     2.dbms_application_info.set_module:根据自己的需要填写自己想要的信息。
     
     3.dbms_application_info.read_client_info和dbms_application_info.read_module读取这三列的信息。

 案例参见：sqlscripts/dbmsApplicationInfoPkgDemo.sql

# 6 Oracle数据库之FORALL与BULK COLLECT语句

## 6.1 PL/SQL块的执行过程
    当PL/SQL运行时引擎处理一块代码时，它使用PL/SQL引擎来执行过程化的代码，而将SQL语句发送给SQL引擎来执行；
    SQL引擎执行完毕后，将结果再返回给PL/SQL引擎。这种在PL/SQL引擎和SQL引擎之间的交互，称为上下文交换（context switch）。
    每发生一次交换，就会带来一定的额外开销。

## 6.2 FORALL和BULK COLLECT特点
这两个语句在PL/SQL内部进行一种数组处理；BULK COLLECT提供对数据的高速检索，FORALL可大大改进INSERT、UPDATE和DELETE操作的性能。Oracle数据库使用这些语句大大减少了PL/SQL与SQL语句执行引擎的环境切换次数，从而使其性能有了显著提高。
    1. FORALL，用于增强PL/SQL引擎到SQL引擎的交换。
    2. BULK COLLECT，用于增强SQL引擎到PL/SQL引擎的交换。

```
如果你要插入5000条数据，一般情况下，在pl/sql中用for循环，循环插入5000次，
而用forall一次就可以插入5000条，提高了性能和速度。
```

## 6.3 FORALL介绍

使用FORALL，可以将多个DML批量发送给SQL引擎来执行，最大限度地减少上下文交互所带来的开销。

### 6.3.1 FORALL语法

```
FORALL index_name IN
    { lower_bound .. upper_bound
     | INDICES OF collection_name [ BETWEEN lower_bound AND upper_bound ]
     | VALUES OF index_collection
    }
 [ SAVE EXCEPTIONS ] dml_statement;
```
说明：
1. index_name：一个无需声明的标识符，作为集合下标使用。
2. lower_bound .. upper_bound：数字表达式，来指定一组连续有效的索引数字下限和上限。该表达式只需解析一次。
3. INDICES OF collection_name：用于指向稀疏数组的实际下标。跳过没有赋值的元素，例如被 DELETE 的元素，NULL 也算值。
4. VALUES OF index_collection_name：把该集合中的值当作下标，且该集合值的类型只能是 PLS_INTEGER/BINARY_INTEGER。
5. SAVE EXCEPTIONS：可选关键字，表示即使一些DML语句失败，直到FORALL LOOP执行完毕才抛出异常。可以使用SQL%BULK_EXCEPTIONS 查看异常信息。
6. dml_statement：静态语句，例如：UPDATE或者DELETE；或者动态（EXECUTE IMMEDIATE）DML语句。

### 6.3.2 FORALL案例

### 6.3.3 FORALL注意事项
使用FORALL时，应该遵循如下规则：
1. FORALL语句的执行体，必须是一个单独的DML语句，比如INSERT，UPDATE或DELETE。
2. 不要显式定义index_row，它被PL/SQL引擎隐式定义为PLS_INTEGER类型，并且它的作用域也仅仅是FORALL。
3. 这个DML语句必须与一个集合的元素相关，并且使用FORALL中的index_row来索引。注意不要因为index_row导致集合下标越界。
4. lower_bound和upper_bound之间是按照步进 1 来递增的。
5. 在sql_statement中，不能单独地引用集合中的元素，只能批量地使用集合。
6. 在sql_statement中使用的集合，下标不能使用表达式。
```
--error statement
--1.insert into test2 values dr_table(i);dbms_output.put_line(i);不正确，找不到i，因为forall中只能使用单条语句可以引用索引变量
--2.insert into test2 values(dr_table(i).id,dr_table(i).name);集合的field不可以在forall中使用，必须是整体使用
--3.insert into test2 values dr_table(i+1);错误，不可以对索引变量进行运算
--4.insert into test2 values(dr_table(i));报没有足够的值错误，此处外面不可以加括号，当有多个字段的时候，单个字段可以加括号
```

## 6.4 BULK COLLECT的使用

### 6.4.1 在SELECT INTO中使用BULK COLLECT

```
DECLARE
  -- 定义记录类型
  TYPE EMP_REC_TYPE IS RECORD(
    EMPNO    EMP.EMPNO%TYPE,
    ENAME    EMP.ENAME%TYPE,
    HIREDATE EMP.HIREDATE%TYPE);
  -- 定义基于记录的嵌套表
  TYPE NESTED_EMP_TYPE IS TABLE OF EMP_REC_TYPE;
  -- 声明变量
  EMP_TAB NESTED_EMP_TYPE;
BEGIN
  -- 使用BULK COLLECT将所得的结果集一次性绑定到记录变量emp_tab中
  SELECT EMPNO, ENAME, HIREDATE BULK COLLECT INTO EMP_TAB FROM EMP;

  FOR I IN EMP_TAB.FIRST .. EMP_TAB.LAST LOOP
    DBMS_OUTPUT.PUT_LINE('当前记录： ' || EMP_TAB(I)
                         .EMPNO || CHR(9) || EMP_TAB(I)
                         .ENAME || CHR(9) || EMP_TAB(I).HIREDATE);
  END LOOP;
END;
```
说明：使用BULK COLLECT一次即可提取所有行并绑定到记录变量，这就是所谓的批量绑定。

### 6.4.2 在FETCH INTO中使用BULK COLLECT
在游标中可以使用BLUK COLLECT一次取出一个数据集合，比用游标单条取数据效率高，尤其是在网络不大好的情况下。

语法：
```
FETCH ... BULK COLLECT INTO ...[LIMIT row_number];
```
在使用BULK COLLECT子句时，对于集合类型会自动对其进行初始化以及扩展。因此如果使用BULK COLLECT子句操作集合，则无需对集合进行初始化以及扩展。
由于BULK COLLECT的批量特性，如果数据量较大，而集合在此时又自动扩展，为避免过大的数据集造成性能下降，因此可以使用LIMIT子句来限制一次提取的数据量。
LIMIT子句只允许出现在FETCH操作语句的批量中.

```

DECLARE
  CURSOR EMP_CUR IS
    SELECT EMPNO, ENAME, HIREDATE FROM EMP;

  TYPE EMP_REC_TYPE IS RECORD(
    EMPNO    EMP.EMPNO%TYPE,
    ENAME    EMP.ENAME%TYPE,
    HIREDATE EMP.HIREDATE%TYPE);
  -- 定义基于记录的嵌套表
  TYPE NESTED_EMP_TYPE IS TABLE OF EMP_REC_TYPE;
  -- 声明集合变量
  EMP_TAB NESTED_EMP_TYPE;
  -- 定义了一个变量来作为limit的值
  V_LIMIT PLS_INTEGER := 5;
  -- 定义变量来记录FETCH次数
  V_COUNTER PLS_INTEGER := 0;
BEGIN
  OPEN EMP_CUR;

  LOOP
    -- fetch时使用了BULK COLLECT子句
    FETCH EMP_CUR BULK COLLECT
      INTO EMP_TAB LIMIT V_LIMIT; -- 使用limit子句限制提取数据量

    EXIT WHEN EMP_TAB.COUNT = 0; -- 注意此时游标退出使用了emp_tab.COUNT，而不是emp_cur%notfound
    V_COUNTER := V_COUNTER + 1; -- 记录使用LIMIT之后fetch的次数

    FOR I IN EMP_TAB.FIRST .. EMP_TAB.LAST LOOP
      DBMS_OUTPUT.PUT_LINE('当前记录： ' || EMP_TAB(I)
                           .EMPNO || CHR(9) || EMP_TAB(I)
                           .ENAME || CHR(9) || EMP_TAB(I).HIREDATE);
    END LOOP;
  END LOOP;

  CLOSE EMP_CUR;

  DBMS_OUTPUT.PUT_LINE('总共获取次数为：' || V_COUNTER);
END;
```

### 6.4.3 在RETURNING INTO中使用BULK COLLECT
BULK COLLECT除了与SELECT，FETCH进行批量绑定之外，还可以与INSERT，DELETE，UPDATE语句结合使用。
当与这几个DML语句结合时，需要使用RETURNING子句来实现批量绑定。

```
DECLARE
  TYPE EMP_REC_TYPE IS RECORD(
    EMPNO    EMP.EMPNO%TYPE,
    ENAME    EMP.ENAME%TYPE,
    HIREDATE EMP.HIREDATE%TYPE);
  TYPE NESTED_EMP_TYPE IS TABLE OF EMP_REC_TYPE;
  EMP_TAB NESTED_EMP_TYPE;
BEGIN
  DELETE FROM EMP
   WHERE DEPTNO = 20 RETURNING EMPNO, ENAME, HIREDATE -- 使用returning 返回这几个列
   BULK COLLECT INTO EMP_TAB; -- 将返回的列的数据批量插入到集合变量

  DBMS_OUTPUT.PUT_LINE('删除 ' || SQL%ROWCOUNT || ' 行记录');
  COMMIT;

  IF EMP_TAB.COUNT > 0 THEN
    -- 当集合变量不为空时，输出所有被删除的元素
    FOR I IN EMP_TAB.FIRST .. EMP_TAB.LAST LOOP
      DBMS_OUTPUT.PUT_LINE('当前记录：' || EMP_TAB(I)
                           .EMPNO || CHR(9) || EMP_TAB(I)
                           .ENAME || CHR(9) || EMP_TAB(I)
                           .HIREDATE || ' 已被删除');
    END LOOP;
  END IF;
END;
```

### 6.4.4 BULK COLLECT的注意事项
1. BULK COLLECT INTO 的目标对象必须是集合类型。
2. 只能在服务器端的程序中使用BULK COLLECT，如果在客户端使用，就会产生一个不支持这个特性的错误。
3. 不能对使用字符串类型作键的关联数组使用BULK COLLECT子句。
4. 复合目标(如对象类型)不能在RETURNING INTO子句中使用。
5. 如果有多个隐式的数据类型转换的情况存在，多重复合目标就不能在BULK COLLECT INTO子句中使用。
6. 如果有一个隐式的数据类型转换，复合目标的集合(如对象类型集合)就不能用于BULK COLLECTINTO子句中

## 6.5 FORALL与BULK COLLECT综合运用
FORALL与BULK COLLECT是实现批量SQL的两个重要方式，我们可以将其结合使用以提高性能.
```
-- create tb_emp_test
 CREATE TABLE tb_emp_test AS
    SELECT empno, ename, hiredate
   FROM   EMP_TEST
   WHERE  1 = 0;

 DECLARE
   -- declare cursor
   CURSOR EMP_CUR IS
     SELECT EMPNO, ENAME, HIREDATE FROM EMP_TEST;
   -- 基于游标的嵌套表类型
   TYPE NESTED_EMP_TYPE IS TABLE OF EMP_CUR%ROWTYPE;
   -- 声明变量
   EMP_TAB NESTED_EMP_TYPE;
 BEGIN
   SELECT EMPNO, ENAME, HIREDATE BULK COLLECT
     INTO EMP_TAB
     FROM EMP_TEST
    WHERE SAL > 1000;

   -- 使用FORALL语句将变量中的数据插入到表tb_emp
   FORALL I IN 1 .. EMP_TAB.COUNT
     INSERT INTO
       (SELECT EMPNO, ENAME, HIREDATE FROM TB_EMP_TEST)
     VALUES EMP_TAB
       (I);

   COMMIT;
   DBMS_OUTPUT.PUT_LINE('总共向 tb_emp 表中插入记录数： ' || EMP_TAB.COUNT);
 END;
```

## 6.6 总结
1. limit减少内存占用，如果数据量较大一次性全部加载到内存中，对PGA来说压力太大，可采用limit的方法一次加载一定数量的数据，建议值通常为1000。使用limit时注意，循环的时候如果用while cursor_name%found loop，对于最后一次fetch的数据量不足设定值1000，%found条件就会不成立。示例使用v_oid_lst.count > 0作为判断条件。
2. 在写plsql代码块，定义数值变量时，建议采用pls_integer类型，或者simple_integer类型，区别：
```
Oracle9i之前有binary_integer类型，和11g中引入的pls_integer数值范围相同：-2147483647~+2147483647，但pls_integer有更高的性能。两者性能均优于number类型。
Oracle中也引入了simple_integer类型，不过不能包含null值，范围：-2147483648~2147483647，性能优于pls_integer。
```
3. 使用ref cursor。
4. 使用绑定变量。
5. 自定义table类型。
6. Bulk collect into加载到内存中，处理完业务逻辑后forall批量插入到数据表中。
7. Forall可以使用returning bulk collect into，且可使用sql%rowcount返回其更新行数。
8. type numbers is table of number index by binary_integer/pls_integer/simple_integer; 其作用是:
```
加了"index by binary_integer "后，numbers类型的下标就是自增长，numbers类型在插入元素时，不需要初始化，不需要每次extend增加一个空间。
而如果没有这句话"index by binary_integer"，那就得要显示对初始化，且每插入一个元素到numbers类型的table中时，都需要先extend。
```