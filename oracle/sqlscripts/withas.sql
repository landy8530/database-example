--with as语法
--–针对一个别名
--with tmp as (select * from tb_name)
--
--–针对多个别名
--with
--   tmp as (select * from tb_name),
--   tmp2 as (select * from tb_name2),
--   tmp3 as (select * from tb_name3),
--   …
with gmg_me_user_review as
  ( select 
      replace(lower(e.email),'github.com','csdn.com') email
      ,e.user_id updated_by
      ,e.user_creation_date
    from 
      um_user_role ur  
      ,um_user u
      ,um_organization o
      ,um_role r
      ,bo_user_role_extension e
    where ur.user_id=u.user_id
      and u.organization_id=o.organization_id
      and lower(o.organization_name) in('landy')
      and ur.role_id=r.role_id
      and lower(r.role_name) in('medicare sales')
      and instr(lower(e.email),'github.com')>0
      and ur.user_role_id=e.user_id
      and e.user_creation_date>=to_date('04/24/2018','mm/dd/yyyy')
    order by 
      r.role_name
      ,e.email
      ,e.user_creation_date desc )
,gmg_me_max_creation as 
  ( select
      email
      ,max(user_creation_date) user_creation_date
    from
      gmg_me_user_review
    group by 
      email )

--GMG MEDICARE SALES LIST (*APPLICATION.ASSOCIATED_ID=UPDATED_BY)
select
  r.email
  ,r.updated_by
from 
  gmg_me_user_review r
  ,gmg_me_max_creation c
where r.email=c.email
  and r.user_creation_date=c.user_creation_date;