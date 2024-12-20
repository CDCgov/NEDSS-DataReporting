create or alter view dbo.v_nrt_srte_totalidm as
select unique_cd,
       SRT_reference as SRT_reference,
       format        as format,
       label         as label
from nbs_srte.dbo.totalidm;