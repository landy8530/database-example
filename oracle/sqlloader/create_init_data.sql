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

-- create temp table ehtemp.EMAIL_APP_LEAD;
create table ehtemp.EMAIL_APP_LEAD
(
  USER_PROFILE_ID         NUMBER,
  LEAD_ID                 NUMBER,
  APPLICATION_ID          NUMBER(10) ,
  EMAIL                   VARCHAR2(100),
  CORRECTED_DO_NOT_MAIL   VARCHAR2(100),
  EMAIL_FLAG              CHAR(2)
)
;


-- create temp table ehtemp.EMAIL_SBG
CREATE TABLE ehtemp.EMAIL_SBG
(
  USER_PROFILE_ID         NUMBER,
  GROUP_ID                NUMBER,
  EMAIL                   VARCHAR2(100),
  CORRECTED_DO_NOT_MAIL   VARCHAR2(100),
  EMAIL_FLAG              CHAR(2)
)
;

-- create temp table ehtemp.EMAIL_FLAG_STATUS
CREATE TABLE ehtemp.EMAIL_FLAG_STATUS
(
  EMAIL_FLAG              CHAR(1), --WEBBULA STATUS
  EMAIL_STATUS_LEAD       VARCHAR2(60),--LEAD STATUS
  EMAIL_STATUS_USER       CHAR(1)  --USER_PROFILE STATUS
)
;

--create primary key
ALTER TABLE ehtemp.EMAIL_FLAG_STATUS add constraint EMAIL_FLAG_STATUS_KEY primary key(EMAIL_FLAG);

-- LEAD STATUS:'Active', 'Bounced', 'Remove/Unsubscribe'
-- send_email in ('Y','N','B')
INSERT INTO ehtemp.EMAIL_FLAG_STATUS VALUES('V','Active','Y');
INSERT INTO ehtemp.EMAIL_FLAG_STATUS VALUES('U','Active','Y');
INSERT INTO ehtemp.EMAIL_FLAG_STATUS VALUES('R','Bounced','B');
INSERT INTO ehtemp.EMAIL_FLAG_STATUS VALUES('F','Bounced','B');
INSERT INTO ehtemp.EMAIL_FLAG_STATUS VALUES('D','Bounced','B');
INSERT INTO ehtemp.EMAIL_FLAG_STATUS VALUES('C','Bounced','B');
INSERT INTO ehtemp.EMAIL_FLAG_STATUS VALUES('I','Bounced','B');

COMMIT ;

PROMPT
set serveroutput on size 1000000
