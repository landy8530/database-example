# Table of Contents

* [1 centos 7.2 mysql5.7 不区分表名大小写](#1-centos-72-mysql57-不区分表名大小写)
* [2 mysql5.7.x:this is incompatible with DISTINCT](#2-mysql57xthis-is-incompatible-with-distinct)


# 1 centos 7.2 mysql5.7 不区分表名大小写
让MYSQL不区分表名大小写的方法其实很简单：
　　1.用ROOT登录，修改/etc/my.cnf
　　2.在[mysqld]下加入一行：lower_case_table_names=1
　　3.重新启动数据库即可

MYSQL在LINUX下数据库名、表名、列名、别名大小写规则如下：
1.数据库名与表名是严格区分大小写的
2.表的别名是严格区分大小写的
3.列名与列的别名在所有的情况下均是忽略大小写的
4.变量名也是严格区分大小写的

# 2 mysql5.7.x:this is incompatible with DISTINCT

DISTINCT关键字经常在MySQL中使用，在mysql5.7以前的版本中一般没有什么问题，但是在5.7以后的版本中会遇到这样的错误。
```
Caused by: java.sql.SQLException: Expression #1 of ORDER BY clause is not in SELECT list, references column ‘game.giftbag0_.create_date’ which is not in SELECT list; this is incompatible with DISTINCT
```

错误提示DISTINCT不兼容，要么更改SQL，但是对于开发者来讲，sql运行一直都是正常的，可能是mysql 版本升级导致的安全问题，5.7.x安全性提升了很多，解决办法可以考虑修改MySQL配置文件,找到对应的my.cnf或者my.ini

```
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
```

还有一种错也是不兼容的问题导致的
Expression #1 of SELECT list is not in GROUP BY clause and contains nonaggregated column ‘nctest.pivot.id’ which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by

这种问题就是sql_mode=only_full_group_by导致的，去掉only_full_group_by就解决了

