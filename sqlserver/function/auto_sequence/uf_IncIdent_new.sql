USE ZXS
GO

/****** Object:  UserDefinedFunction [dbo].[uf_IncIdent]    Script Date: 2018/10/30 21:27:45 ******/
DROP FUNCTION [dbo].[uf_IncIdent]
GO

/****** Object:  UserDefinedFunction [dbo].[uf_IncIdent]    Script Date: 2018/10/30 21:27:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--下面函数实现在sqlserver中产生带字母流水号,如ABC增加一个为ABD,  ABCD 递增为ABCE
create function uf_IncIdent(@p_AIdent varchar(36))
-- print ZXS.dbo.uf_IncIdent('9YZZ')
--print ZXS.dbo.uf_IncIdent('9Z00')
--print ZXS.dbo.uf_IncIdent('9ZZZ')
--print ZXS.dbo.uf_IncIdent('9999')
--print ZXS.dbo.uf_IncIdent('999Z')
--print ZXS.dbo.uf_IncIdent('9Z9Z')
returns varchar(20)
as
begin
	declare	@v_cChars	varchar(40),@v_J	int,@v_K	int,@v_result	varchar(40)
	declare @v varchar(40)

	declare @id char(2)
	declare @index int
	declare @idx int
	declare @seqno char(1)

	declare @ioseq_tbl table (
		 idx bigint ,
		 seqno char(1)
	);
	--倒叙插叙
	insert into @ioseq_tbl select * from dbo.uf_get_ioseq_table(@p_AIdent)  

	declare cur_seq  cursor for
		select idx,seqno from @ioseq_tbl order by idx desc
	open    cur_seq
	fetch next from cur_seq  into	@index,@seqno
	while ( @@fetch_status <> -1 )
	begin
		set @idx = dbo.uf_get_index_seqno(@seqno) --最后一位字符开数加1
		--print @idx
		--set @idx = @idx - 1						
		set @id = dbo.uf_get_next_id(@idx);
		--print @id		
		if @id <> '0' 
		begin
			update @ioseq_tbl set seqno = @id where idx = @index;
			break
		end 
		else
		begin
			update @ioseq_tbl set seqno = @id where idx = @index;
		end 		

	fetch next from cur_seq  into @index,@seqno
	end
	close cur_seq
	deallocate cur_seq

	SELECT @v_result = STUFF((SELECT ','+seqno  FROM @ioseq_tbl order by idx FOR XML PATH('')),1,1,'');
	--SELECT @v_result = seqno FROM @ioseq_tbl order by idx FOR XML PATH('') 

	set @v_result = REPLACE(@v_result,',','')

	return @v_result 
end
 


