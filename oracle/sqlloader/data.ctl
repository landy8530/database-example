OPTIONS (skip=1,rows=128)
LOAD DATA
INFILE 'data.csv'
BADFILE 'data.bad'
DISCARDFILE 'data.dsc'
TRUNCATE
INTO TABLE EMAIL_APP_LEAD
fields terminated by ','
TRAILING NULLCOLS 
(
  USER_PROFILE_ID ,
  LEAD_ID         ,
  APPLICATION_ID  ,
  EMAIL           ,
  CORRECTED_DO_NOT_MAIL ,
  EMAIL_FLAG            
)
