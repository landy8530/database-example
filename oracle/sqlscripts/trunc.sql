select trunc(sysdate) from dual;--2017/2/13,返回当前时间
select trunc(sysdate,'yy') from dual;--2017/1/1,返回当年第一天
select trunc(sysdate,'mm') from dual;--2017/2/1,返回当月的第一天
select trunc(sysdate,'d') from dual;--2017/2/12,返回当前星期的第一天，即星期天
select trunc(sysdate,'dd') from dual;--2017/2/13,返回当前日期,今天是2017/2/13
select trunc(sysdate ,'HH24') from dual;--2017/2/13 15:00:00,返回本小时的开始时间
select trunc(sysdate ,'MI') from dual;--2017/2/13 15:13:00,返回本分钟的开始时间


----------------------------------------------------------------
select trunc(123.567,2) from dual;--123.56,将小数点右边指定位数后面的截去;
select trunc(123.567,-2) from dual;--100,第二个参数可以为负数，表示将小数点左边指定位数后面的部分截去，即均以0记;
select trunc(123.567) from dual;--123,默认截去小数点后面的部分;