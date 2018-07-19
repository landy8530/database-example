  --该函数把传递过来的字符串转换成IN 后面的列表，可以处理以分号，逗号以及空格分隔的字符串
CREATE FUNCTION [dbo].[GetInStr]
             (@SourceStr varchar(2000))--源字符串

RETURNS  @table table(list  varchar(50) )
  AS
BEGIN

--  select @sourcestr =  replace(@sourcestr,';',',')
--  select @sourcestr = replace(@sourcestr,' ',',')
 --declare @OutStr varchar(200)
   if charindex(',',@sourcestr)>0
    begin
      declare @i int
      declare @n int
      set @i=1
      while charindex(',',@sourcestr,@i)>0
        begin
           set @n=charindex(',',@sourcestr,@i)
           insert into @table values(substring(@sourcestr,@i, @n-@i) )
           set @i=@n+1
        end
        insert into @table values(substring(@sourcestr,@i,len(@sourcestr)-@i+1))
    end  else insert into @table values(@sourcestr)

  delete from @table where isnull(list,'') = ''
return
END
