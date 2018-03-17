OPTIONS (skip=1,rows=128) -- sqlldr 命令显示的选项可以写到这里边来,skip=1 用来跳过数据中的第一行
LOAD DATA
INFILE 'data.csv' --指定外部数据文件，可以写多个 INFILE "another_data_file.csv" 指定多个数据文件
BADFILE 'data.bad' --这里还可以使用 BADFILE、DISCARDFILE 来指定坏数据和丢弃数据的文件，
DISCARDFILE 'data.dsc'
TRUNCATE --操作类型，用 truncate table 来清除表中原有记录
INTO TABLE EMAIL_APP_LEAD -- 要插入记录的表
fields terminated by ','  -- 数据中每行记录用 "," 分隔
TRAILING NULLCOLS  --表的字段没有对应的值时允许为空
(
  USER_PROFILE_ID ,--字段可以指定类型，否则认为是 CHARACTER 类型, log 文件中有显示
  LEAD_ID         ,
  APPLICATION_ID  ,
  EMAIL           ,
  CORRECTED_DO_NOT_MAIL ,
  EMAIL_FLAG            
)
