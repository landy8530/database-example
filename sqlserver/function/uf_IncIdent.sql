USE [XHF]
GO

/****** Object:  UserDefinedFunction [dbo].[uf_IncIdent]    Script Date: 2018/10/30 21:47:34 ******/
DROP FUNCTION [dbo].[uf_IncIdent]
GO

/****** Object:  UserDefinedFunction [dbo].[uf_IncIdent]    Script Date: 2018/10/30 21:47:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--下面函数实现在sqlserver中产生带字母流水号,如ABC增加一个为ABD,  ABCD 递增为ABCE
create  function [dbo].[uf_IncIdent](@p_AIdent varchar(36))
-- print dbo.uf_IncIdent('000Z')
returns varchar(20)
as   
begin
  declare  @v_cChars varchar(40),
  @v_J integer,
  @v_K Integer,
  @v_result varchar(40);
   set @v_cChars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  set @v_Result = @p_AIdent;
  set @v_j= Len(@p_AIdent)
  while @v_J >1
  begin
    SET @v_K = CHARINDEX(SUBSTRING(@P_AIdent,@V_J,1), @V_cChars);
    if @V_K < Len(@V_cChars)
    begin
      set @v_result=substring(@v_result,1,@v_J-1)+SUBSTRING(@V_cChars,@v_k+1,1)+substring(@v_result,@v_J+1,40)
      SET @V_K=Len(@P_AIdent)
      while @v_k>@V_J
      begin
          set @v_result=substring(@v_result,1,@v_k-1)+substring(@v_cChars,1,1)+substring(@v_result,@v_k+1,40)
          set @v_k=@v_k-1;
      end;
      return @v_result;
      break;
    end;
   set  @v_J=@v_J-1;
  end;
 return @v_result;
end;


GO


