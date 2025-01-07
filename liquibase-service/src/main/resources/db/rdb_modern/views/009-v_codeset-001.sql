create or alter view dbo.v_codeset as
select m.unique_cd          as CD,
       RDB_table            as TBL_NM,
       RDB_attribute        as COL_NM,
       c.source_version_txt as CD_SYS_VER,
       null                 as DATA_TYPE,
       null                 as DATA_LENGTH,
       t.srt_reference      as code_set_nm,
       t.label              as cd_desc
from dbo.v_nrt_srte_imrdbmapping m
         left join dbo.v_nrt_srte_totalidm t on t.unique_cd = m.unique_cd
         left join dbo.v_nrt_srte_codeset c on c.code_set_nm = t.srt_reference;
