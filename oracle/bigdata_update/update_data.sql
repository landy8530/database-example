DECLARE
  MAX_ROWS NUMBER DEFAULT 10000;

  --APP
  ROW_ID_TABLE_APP     DBMS_SQL.UROWID_TABLE;
  EMAIL_FLAG_TABLE_APP DBMS_SQL.VARCHAR2_TABLE;
  --LEAD
  ROW_ID_TABLE_LEAD     DBMS_SQL.UROWID_TABLE;
  EMAIL_FLAG_TABLE_LEAD DBMS_SQL.VARCHAR2_TABLE;
  --SBG
  ROW_ID_TABLE_SBG     DBMS_SQL.UROWID_TABLE;
  EMAIL_FLAG_TABLE_SBG DBMS_SQL.VARCHAR2_TABLE;

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

  -- LEAD CURSOR  
  CURSOR EMAIL_LEAD_CUR IS
    SELECT /*+ use_hash(t1,t2) parallel(t1,4) parallel(t2,4) */
     T3.EMAIL_STATUS_LEAD, T1.ROWID
      FROM LEAD                              T1,
           EMAIL_APP_LEAD    T2,
           EMAIL_FLAG_STATUS T3
     WHERE T1.LEAD_ID = T2.LEAD_ID
       AND T2.EMAIL_FLAG = T3.EMAIL_FLAG
       AND T2.LEAD_ID IS NOT NULL
     ORDER BY T1.ROWID;

  -- SBG CURSOR
  CURSOR EMAIL_SBG_CUR IS
    SELECT /*+ use_hash(t1,t2) parallel(t1,4) parallel(t2,4) */
     T3.EMAIL_STATUS_USER, T1.ROWID
      FROM USER_PROFILE                      T1,
           EMAIL_SBG         T2,
           EMAIL_FLAG_STATUS T3
     WHERE T1.USER_PROFILE_ID = T2.USER_PROFILE_ID
       AND T2.EMAIL_FLAG = T3.EMAIL_FLAG
       AND T2.USER_PROFILE_ID IS NOT NULL
     ORDER BY T1.ROWID;

BEGIN
  DBMS_APPLICATION_INFO.SET_MODULE('EHI_APP', '');
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

  --UPDATE LEAD
  OPEN EMAIL_LEAD_CUR;
  LOOP
    EXIT WHEN EMAIL_LEAD_CUR%NOTFOUND;
    FETCH EMAIL_LEAD_CUR BULK COLLECT
      INTO EMAIL_FLAG_TABLE_LEAD, ROW_ID_TABLE_LEAD LIMIT MAX_ROWS;
    FORALL I IN 1 .. ROW_ID_TABLE_LEAD.COUNT
      UPDATE LEAD
         SET EMAIL_STATUS = EMAIL_FLAG_TABLE_LEAD(I),UPDATED_BY = 'BKOF-7959-Webbula',UPDATED_WHEN=SYSDATE
       WHERE ROWID = ROW_ID_TABLE_LEAD(I);
    COMMIT;
  END LOOP;

  --UPDATE USER_PROFILE FROM SBG
  OPEN EMAIL_SBG_CUR;
  LOOP
    EXIT WHEN EMAIL_SBG_CUR%NOTFOUND;
    FETCH EMAIL_SBG_CUR BULK COLLECT
      INTO EMAIL_FLAG_TABLE_SBG, ROW_ID_TABLE_SBG LIMIT MAX_ROWS;
    FORALL I IN 1 .. ROW_ID_TABLE_SBG.COUNT
      UPDATE USER_PROFILE
         SET SEND_EMAIL = EMAIL_FLAG_TABLE_SBG(I),UPDATED_BY = 'BKOF-7959-Webbula',UPDATED_WHEN=SYSDATE
       WHERE ROWID = ROW_ID_TABLE_SBG(I);
    COMMIT;
  END LOOP;

END;


-- 强制 Oracle 执行，方法是加上 BYPASS_UJVC 注释
--使用这种方式来更新表，需要用于更新的表(最终数据表)的关联字段必须设置为主键，且不可多字段主键。
--If the user has update permission on table A, but only has select permission on table B, they cannot update via the first example.
-- Oracle will return ORA-01031 (insufficient privileges).
/*UPDATE (SELECT \*+ BYPASS_UJVC *\
         T1.SEND_EMAIL, T3.EMAIL_STATUS_USER
          FROM USER_PROFILE                      T1,
               EMAIL_APP_LEAD    T2,
               EMAIL_FLAG_STATUS T3
         WHERE T1.USER_PROFILE_ID = T2.USER_PROFILE_ID
           AND T2.EMAIL_FLAG = T3.EMAIL_FLAG
           AND T2.USER_PROFILE_ID IS NOT NULL) R
   SET R.SEND_EMAIL = R.EMAIL_STATUS_USER;*/


 -- UPDATE LEAD

 /*UPDATE (SELECT \*+ BYPASS_UJVC *\
          T1.EMAIL_STATUS, T3.EMAIL_STATUS_LEAD
           FROM LEAD                              T1,
                EMAIL_APP_LEAD    T2,
                EMAIL_FLAG_STATUS T3
          WHERE T1.LEAD_ID = T2.LEAD_ID
            AND T2.EMAIL_FLAG = T3.EMAIL_FLAG
            AND T2.LEAD_ID IS NOT NULL) R
    SET R.EMAIL_STATUS = R.EMAIL_STATUS_LEAD;*/




-- 分析过程

-- 更新app 和lead 需要注意,循环EMAIL_APP_LEAD 中的数据，
-- 1.如果user_profile_id有值，就用user_profile_id直接更新user_profile中的状态
-- 2.如果lead_id有值，需要同步更新lead表中的email_status
-- 3.确认一下corrected do not mail 列对应的是不是全是应该改成bounced的？如果是可以忽略这列，反正我们用appid和leadid匹配数据。
-- 4.user_profile_id 和lead_id 同时为空是不存在的,所以app_id可以不理会

-- 更新sbg也是只要根据user_profile_id 更新即可

-- SELECT COUNT(1) FROM USER_PROFILE

-- SELECT count(DISTINCT user_profile_id) FROM EMAIL_APP_LEAD ;

 -- corrected do not mail 列对应的全是应该改成bounced的
-- SELECT * FROM EMAIL_APP_LEAD WHERE corrected_do_not_mail IS NOT NULL ;

 -- user_profile_id 和lead_id 同时为空是不存在的
-- SELECT * FROM EMAIL_APP_LEAD WHERE user_profile_id IS  NULL AND lead_id IS NULL ;

 --SBG 中，user_profile_id 为空也是不存在的
-- SELECT COUNT(1) FROM EMAIL_SBG WHERE user_profile_id IS NULL ;
 
 --
--  SELECT * FROM EMAIL_APP_LEAD WHERE user_profile_id IS NOT NULL AND email_flag IS NULL ;