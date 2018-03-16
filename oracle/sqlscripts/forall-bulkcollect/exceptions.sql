--表说明：ALL_OBJECTS_TEST数据来自：all_objects；ALL_OBJECTS_TEMP有两个字段：col字符型最大长度10，num数值型。

CREATE TABLE ALL_OBJECTS_TEST AS SELECT * FROM ALL_OBJECTS;
CREATE TABLE ALL_OBJECTS_TEMP (
   COL VARCHAR(10),
   NUM NUMBER
);

DECLARE
  TYPE V_TP_REC IS RECORD(
    OBJECT_NAME VARCHAR2(50),
    OBJECT_ID   NUMBER);
  TYPE V_TP_OBJ IS TABLE OF V_TP_REC INDEX BY SIMPLE_INTEGER;
  V_OBJS V_TP_OBJ;
  TYPE V_CUR_TP_OBJ IS REF CURSOR;
  V_CUR_OBJ V_CUR_TP_OBJ;
  V_LMT_CNT SIMPLE_INTEGER := 1000;
  V_RN      SIMPLE_INTEGER := 10;
BEGIN
  OPEN V_CUR_OBJ FOR 'select object_name,object_id from ALL_OBJECTS_TEST where rownum<=:1 order by decode(object_id,117,300)'
    USING V_RN;
  FETCH V_CUR_OBJ BULK COLLECT
    INTO V_OBJS LIMIT V_LMT_CNT;
  WHILE V_OBJS.COUNT > 0 LOOP
    DBMS_OUTPUT.PUT_LINE('v_objs.first=' || V_OBJS.FIRST);
    FOR I IN V_OBJS.FIRST .. V_OBJS.LAST LOOP
      V_OBJS(I).OBJECT_ID := V_OBJS(I).OBJECT_ID + 1;
    END LOOP;
    BEGIN
      ----批量插入，ALL_OBJECTS_TEMP表col字段大小为10，这里有异常
      FORALL I IN V_OBJS.FIRST .. V_OBJS.LAST
        INSERT INTO ALL_OBJECTS_TEMP
          (COL, NUM)
        VALUES
          (V_OBJS(I).OBJECT_NAME, V_OBJS(I).OBJECT_ID);
    EXCEPTION
      --如果不对forall执行异常捕获，数据执行过程中如果出错，会全部回滚，
      --如果捕获异常，假如数据在执行第5条时出错，则前4条数据执行成功，第5条及其后面所有数据都不再执行。
      WHEN OTHERS THEN
         --sql%bulk_exceptions.count记录异常数量，如果没有使用save exceptions,若有异常该值为1，如下输出是1
        DBMS_OUTPUT.PUT_LINE('sql%bulk_exceptions.count:' ||
                             SQL%BULK_EXCEPTIONS.COUNT);
    END;
     --批量更新
    FORALL I IN V_OBJS.FIRST .. V_OBJS.LAST
      UPDATE ALL_OBJECTS_TEMP
         SET NUM = V_OBJS(I).OBJECT_ID
       WHERE COL = V_OBJS(I).OBJECT_NAME;
    --对于批量更新，除了sql%rowcount几个隐式游标属性外，另具有sql%bulk_rowcount属性，用来记录第N行更新影响行数。
    IF SQL%BULK_ROWCOUNT(2) > 0 THEN
      DBMS_OUTPUT.PUT_LINE('µÚ¶þÐÐ¸üÐÂÓ°ÏìÐÐÊý£º' || SQL%BULK_ROWCOUNT(2));
    END IF;
    BEGIN
      --批量删除，使用save exceptions,和之前异常捕获区别：使用save exceptions异常后可继续执行直至结束。
      --新属性：sql%bulk_exceptions.count、sql%bulk_exceptions(i).error_index、sql%bulk_exceptions(i).error_code
      FORALL I IN V_OBJS.FIRST .. V_OBJS.LAST SAVE EXCEPTIONS
        DELETE FROM ALL_OBJECTS_TEMP WHERE V_OBJS(I).OBJECT_ID / 0 > 1;

      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        FOR I IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
          DBMS_OUTPUT.PUT_LINE('sql%bulk_exceptions(i).error_index:' ||
                               SQL%BULK_EXCEPTIONS(I).ERROR_INDEX);
          DBMS_OUTPUT.PUT_LINE('sqlerrm sql%bulk_exceptions(i).error_code:' ||
                               SQLERRM(SQL%BULK_EXCEPTIONS(I).ERROR_CODE));
        END LOOP;
    END;
    FETCH V_CUR_OBJ BULK COLLECT
      INTO V_OBJS LIMIT V_LMT_CNT;
  END LOOP;
  CLOSE V_CUR_OBJ;
END;