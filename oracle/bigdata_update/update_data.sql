whenever sqlerror exit 0
PROMPT
set timing on

set serveroutput on size 1000000
declare
  --Note: In the imported temporary data,
  --the email_flag field needs to clear special characters such as newline(chr(10)), carriage return(chr(13)), and space. (completed)
  vDatabase             VARCHAR2(30)   := NULL;
  vUnsupportedDatabase  EXCEPTION;
  vSQL                  VARCHAR2(1000) := NULL;




BEGIN
    DBMS_APPLICATION_INFO.SET_MODULE('MY_APP', '');

    vDatabase := GET_DATABASE_NAME;

    -- =======================================================
	-- Only run on xhf
    if (vDatabase in('PROD'))  then
        NULL;
    else
    	RAISE vUnsupportedDatabase;
    end if;

    EXCEPTION

        -- Correct skip of the database. The Code that exists
        -- outside of this block will need to run on the database.
        -- The reason why this exception was raised is because I
        -- needed to SELECTIVELY execute the code that is shown in
        -- the PL/SQL block shown above.
        -- ======================================================
       	WHEN vUnsupportedDatabase then
       	    	RAISE_APPLICATION_ERROR(-20000,'ERROR: this SQL script should not be run on the ' || vDatabase || ' database.');

       	WHEN OTHERS then

       	    RAISE_APPLICATION_ERROR(-20001,SQLERRM(SQLCODE));

END;
/

whenever sqlerror exit -1;

PROMPT --create PROCEDURE update_email_status
CREATE OR REPLACE PROCEDURE update_email_status AUTHID CURRENT_USER AS
  /********************************************************************************
    NAME:       update_email_status
    PURPOSE:

    REVISIONS:
    Ver        Date        Author           Description
    ---------  ----------  ---------------  ------------------------------------
    1          2018-03-12  Landy.Liu        1. Created this procedure.

    castro version:1
  ********************************************************************************/

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

  vUpdateEmailStatusAsErrors      EXCEPTION;

BEGIN

  declare
  -- APP CURSOR
  CURSOR EMAIL_APP_CUR IS
    SELECT /*+ use_hash(t1,t2) parallel(t1,4) parallel(t2,4) */
     T3.EMAIL_STATUS_USER, T1.ROWID
      FROM USER_PROFILE                      T1,
           EHTEMP.T_TEST_SQL_LOAD    T2,
           EHTEMP.EMAIL_FLAG_STATUS T3
     WHERE TRIM(T2.EMAIL_FLAG) = TRIM(T3.EMAIL_FLAG)
       AND LOWER(T1.LOGIN_ID) = LOWER(T2.EMAIL(+))
     ORDER BY T1.ROWID;

  -- LEAD CURSOR
  CURSOR EMAIL_LEAD_CUR IS
    SELECT /*+ use_hash(t1,t2) parallel(t1,4) parallel(t2,4) */
     T3.EMAIL_STATUS_LEAD, T1.ROWID
      FROM LEAD                              T1,
           EHTEMP.T_TEST_SQL_LOAD    T2,
           EHTEMP.EMAIL_FLAG_STATUS T3
     WHERE TRIM(T2.EMAIL_FLAG) = TRIM(T3.EMAIL_FLAG)
     AND LOWER(T1.EMAIL) = LOWER(T2.EMAIL(+))
     ORDER BY T1.ROWID;

  -- SBG CURSOR
  CURSOR EMAIL_SBG_CUR IS
    SELECT /*+ use_hash(t1,t2) parallel(t1,4) parallel(t2,4) */
     T3.EMAIL_STATUS_USER, T1.ROWID
      FROM USER_PROFILE                      T1,
           EHTEMP.EMAIL_SBG         T2,
           EHTEMP.EMAIL_FLAG_STATUS T3
     WHERE TRIM(T2.EMAIL_FLAG) = TRIM(T3.EMAIL_FLAG)
       AND LOWER(T1.LOGIN_ID) = LOWER(T2.EMAIL(+))
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

      EXCEPTION
      WHEN vUpdateEmailStatusAsErrors THEN
             rollback;
             DBMS_OUTPUT.PUT_LINE('Update email status error from Webbula !');
      WHEN OTHERS then
             ROLLBACK;
             DBMS_OUTPUT.PUT_LINE('Fatal error: ' || SUBSTR(SQLERRM,1,200));
   END;
END update_email_status;
/
show errors;

exec update_email_status;
drop procedure update_email_status;

PROMPT
set serveroutput on size 1000000


-- 强制 Oracle 执行，方法是加上 BYPASS_UJVC 注释
--使用这种方式来更新表，需要用于更新的表(最终数据表)的关联字段必须设置为主键，且不可多字段主键。
--If the user has update permission on table A, but only has select permission on table B, they cannot update via the first example.
-- Oracle will return ORA-01031 (insufficient privileges).
/*UPDATE (SELECT \*+ BYPASS_UJVC *\
         T1.SEND_EMAIL, T3.EMAIL_STATUS_USER
          FROM USER_PROFILE                      T1,
               T_TEST_SQL_LOAD    T2,
               EMAIL_FLAG_STATUS T3
         WHERE T1.USER_PROFILE_ID = T2.USER_PROFILE_ID
           AND T2.EMAIL_FLAG = T3.EMAIL_FLAG
           AND T2.USER_PROFILE_ID IS NOT NULL) R
   SET R.SEND_EMAIL = R.EMAIL_STATUS_USER;*/


 -- UPDATE LEAD

 /*UPDATE (SELECT \*+ BYPASS_UJVC *\
          T1.EMAIL_STATUS, T3.EMAIL_STATUS_LEAD
           FROM LEAD                              T1,
                T_TEST_SQL_LOAD    T2,
                EMAIL_FLAG_STATUS T3
          WHERE T1.LEAD_ID = T2.LEAD_ID
            AND T2.EMAIL_FLAG = T3.EMAIL_FLAG
            AND T2.LEAD_ID IS NOT NULL) R
    SET R.EMAIL_STATUS = R.EMAIL_STATUS_LEAD;*/

