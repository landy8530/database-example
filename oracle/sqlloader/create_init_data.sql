-- create temp table EMAIL_APP_LEAD;
create table EMAIL_APP_LEAD
(
  USER_PROFILE_ID         NUMBER ,
  LEAD_ID                 NUMBER,
  APPLICATION_ID          NUMBER(10) ,
  EMAIL                   VARCHAR2(100) ,
  CORRECTED_DO_NOT_MAIL   VARCHAR2(100),
  EMAIL_FLAG              CHAR(2)
) ;


-- create temp table EMAIL_SBG
create table EMAIL_SBG
(
  USER_PROFILE_ID         NUMBER ,
  GROUP_ID                NUMBER,
  EMAIL                   VARCHAR2(100),
  CORRECTED_DO_NOT_MAIL   VARCHAR2(100),
  EMAIL_FLAG              CHAR(2) 
) ;

-- create temp table EMAIL_FLAG_STATUS
create table EMAIL_FLAG_STATUS
(
  EMAIL_FLAG              CHAR(2), --WEBBULA STATUS
  EMAIL_STATUS_LEAD       VARCHAR2(60),--LEAD STATUS
  EMAIL_STATUS_USER       CHAR(2)  --USER_PROFILE STATUS
) ;

--create primary key
alter table EMAIL_FLAG_STATUS add constraint EMAIL_FLAG_STATUS_KEY primary key(EMAIL_FLAG);
--create index
CREATE UNIQUE INDEX EMAIL_FLAG_STATUS_idx_001 ON EMAIL_FLAG_STATUS (EMAIL_FLAG);

-- LEAD STATUS:'Active', 'Bounced', 'Remove/Unsubscribe'
-- send_email in ('Y','N','B')
INSERT INTO EMAIL_FLAG_STATUS VALUES('V','Active','Y');
INSERT INTO EMAIL_FLAG_STATUS VALUES('U','Active','Y');
INSERT INTO EMAIL_FLAG_STATUS VALUES('R','Bounced','B');
INSERT INTO EMAIL_FLAG_STATUS VALUES('F','Bounced','B');
INSERT INTO EMAIL_FLAG_STATUS VALUES('D','Bounced','B');
INSERT INTO EMAIL_FLAG_STATUS VALUES('C','Bounced','B');
INSERT INTO EMAIL_FLAG_STATUS VALUES('I','Bounced','B');

COMMIT ;

