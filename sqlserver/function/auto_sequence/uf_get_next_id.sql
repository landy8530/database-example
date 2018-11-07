USE ZXS
GO

/****** Object:  UserDefinedFunction [dbo].[uf_get_next_id]    Script Date: 2018/10/30 21:27:45 ******/
DROP FUNCTION [dbo].[uf_get_next_id]
GO

/****** Object:  UserDefinedFunction [dbo].[uf_get_next_id]    Script Date: 2018/10/30 21:27:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--根据索引值得到该索引对应下一个索引对应的id值
create function uf_get_next_id(@index int)
-- print xhf.dbo.uf_get_next_id(35)
-- print xhf.dbo.uf_get_next_id(9)
returns char(1)
as
begin
	declare	@id	char(1);

	declare @index_table table (
		 idx int,
		 id  char(1)
	);

	WITH x AS
    (SELECT 0 AS id,CHAR(ascii('0')) AS cc UNION ALL
    SELECT id + 1 AS id,CASE WHEN id<9 THEN CHAR(ascii('1')+id) ELSE CHAR(ascii('a')+id-9) END AS cc
    FROM x
    WHERE id < 35)
	insert into @index_table 
	SELECT id, upper(cc) cc FROM x;

	if @index = 35 
		set @index = 0
	else
		set @index = @index + 1


	select @id = id from @index_table where idx = @index;

	return @id;
end
 


