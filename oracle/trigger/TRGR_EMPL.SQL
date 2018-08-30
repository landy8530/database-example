CREATE OR REPLACE TRIGGER trgr_empl
BEFORE INSERT OR UPDATE
ON empl
FOR EACH ROW
/****************************************************************************
   NAME:       trgr_empl
   PURPOSE:
      1. Set value for below columns in the empl table automatically.
         (1) CREATED_WHEN
         (2) UPDATED_WHEN

   REVISIONS:
   VER        DATE        AUTHOR         DESCRIPTION
   ---------  ----------  -------------  ------------------------------------
   1          2018-08-10  Landy Liu       Modify EMPL tables to meet new requirements

   Last GIT DatabaseObject-Procedures version:36a1086c88f
*****************************************************************************/
DECLARE
  vInvalidUpdatedBy		EXCEPTION;

BEGIN
   --只要有更新的时候，没有更新 updated_by 就会报错，updated_by必须要更新
   IF UPDATING THEN
       IF NOT UPDATING('updated_by') THEN
           RAISE vInvalidUpdatedBy;
       END IF;
   END IF;

   IF INSERTING THEN
      :new.created_when := SYSDATE;
   END IF;

   :new.updated_when := SYSDATE;

EXCEPTION
  	when vInvalidUpdatedBy THEN
      		RAISE_APPLICATION_ERROR( -20001, 'Error: updated_by should be not null!');

END trgr_empl;
/
show errors TRIGGER trgr_empl;