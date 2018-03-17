whenever sqlerror exit 0
PROMPT
set timing on

set serveroutput on size 1000000
declare

vDatabase             VARCHAR2(30)   := NULL;
vUnsupportedDatabase  EXCEPTION;
vSQL                  VARCHAR2(1000) := NULL;

BEGIN

    vDatabase := GET_DATABASE_NAME;

    -- =======================================================
	-- Only run on EHI
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

-- create temp table EMAIL_APP_LEAD;
create table EMAIL_APP_LEAD
(
  USER_PROFILE_ID         NUMBER,
  LEAD_ID                 NUMBER,
  APPLICATION_ID          NUMBER(10) ,
  EMAIL                   VARCHAR2(100),
  CORRECTED_DO_NOT_MAIL   VARCHAR2(100),
  EMAIL_FLAG              CHAR(2)
)
;

PROMPT
set serveroutput on size 1000000
