CREATE TABLE EMPL
(
  EMPL_ID            NUMBER  NOT NULL,
  EMPL_TYPE               VARCHAR2(20)  NOT NULL,
  IS_ACTIVE                       NUMBER(1) default 1 NOT NULL,
  CREATED_BY                      VARCHAR2(300)  NOT NULL,
  CREATED_WHEN                    DATE  NOT NULL,
  UPDATED_BY                      VARCHAR2(300)  NOT NULL,
  UPDATED_WHEN                    DATE  NOT NULL
);
