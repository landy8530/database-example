-- FORALL与BULK COLLECT综合运用
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
   DBMS_OUTPUT.PUT_LINE('×Ü¹²Ïò tb_emp ±íÖÐ²åÈë¼ÇÂ¼Êý£º ' || EMP_TAB.COUNT);
 END;