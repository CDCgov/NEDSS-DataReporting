--There is no NULL row assigned to CODE_KEY =1
create or alter view dbo.v_code_value_general as
select v.code                 as CODE_VAL,
       v.code_short_desc_txt  as CODE_DESC,
       v.code_system_cd       as CODE_SYS_CD,
       v.code_system_desc_txt as CODE_SYS_CD_DESC,
       v.effective_from_time  as CODE_EFF_DT,
       v.effective_to_time    as CODE_END_DT,
       c.cd,
       ROW_NUMBER () over (ORDER BY c.cd) AS CODE_KEY
from dbo.v_codeset c
         join
     dbo.v_nrt_srte_code_Value_General v
     on c.code_set_nm = v.code_set_nm;