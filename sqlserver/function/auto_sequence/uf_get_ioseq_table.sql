USE ZXS
GO

/****** Object:  UserDefinedFunction [dbo].[uf_get_ioseq_table]    Script Date: 2018/10/30 21:27:45 ******/
DROP FUNCTION [dbo].[uf_get_ioseq_table]
GO

/****** Object:  UserDefinedFunction [dbo].[uf_get_ioseq_table]    Script Date: 2018/10/30 21:27:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--根据索引值得到该索引对应下一个索引对应的id值
create function uf_get_ioseq_table(@ioseq char(4))
-- print xhf.dbo.uf_get_ioseq_table(35)
-- print xhf.dbo.uf_get_ioseq_table(9)
returns @ioseq_table table (
		 idx bigint identity(1,1),
		 seqno char(1)
	)
as
begin
	declare	@id	char(1);

	--declare @ioseq_tbl table (
	--	 idx bigint identity(1,1),
	--	 seqno char(1)
	--);

	WITH ioseq_table(seqno) AS (
		SELECT @ioseq 
	)
	insert into @ioseq_table(seqno) 
	SELECT SUBSTRING(t.seqno,n.number,1) seqno
	  FROM ioseq_table t
	  JOIN (SELECT number
			  FROM master..spt_values
			 WHERE type = 'p'
			   AND number > 0
		   ) n
		ON n.number <= LEN(t.seqno)
	
	

	return ;
end
 


