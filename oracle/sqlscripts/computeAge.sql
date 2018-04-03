--oracle中SQL根据生日日期查询年龄的方法

--方法：SELECT Trunc(MONTHS_BETWEEN(SYSDATE,BIRTH_DATE)/12) FROM 某表
--
--Trunc函数在这里对带有小数位数的数字取整数部分；
--
--SYSDATE为oracle的获取当前日期的函数；
--
--BIRTH_DATE为我自己的数据库表中存储生日日期的字段。



--实际执行SQL:

--根据出生日期计算年龄
SELECT Trunc(MONTHS_BETWEEN(
       to_date(to_char(sysdate, 'yyyy-MM-dd'),'yyyy-MM-dd'),to_date('1990-09-30', 'yyyy-MM-dd'))/12)
from dual;
