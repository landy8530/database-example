USE ZXS
GO

/****** Object:  UserDefinedFunction [dbo].[uf_get_index_seqno]    Script Date: 2018/10/30 21:27:45 ******/
DROP FUNCTION [dbo].[uf_get_index_seqno]
GO

/****** Object:  UserDefinedFunction [dbo].[uf_get_index_seqno]    Script Date: 2018/10/30 21:27:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--根据序号得到该序号对应id值
create function uf_get_index_seqno(@seqno char(1))
-- print xhf.dbo.uf_get_index_seqno('Z')
-- print xhf.dbo.uf_get_index_seqno('9')
returns int
as
begin
	declare	@idx	int;

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

	

	select @idx = idx from @index_table where id = upper(@seqno);

	return @idx;
end
 


