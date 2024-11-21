CREATE OR ALTER VIEW dbo.v_getobscode
AS
WITH InvFormQObservations AS
         (
             SELECT
                 public_health_case_uid
                  ,observation_id
                  ,branch_id
                  ,branch_type_cd
                  ,ovc.ovc_code
             FROM
                 dbo.nrt_investigation_observation tnio with (nolock)
                     inner join dbo.nrt_observation_coded ovc with (nolock) ON ovc.observation_uid = tnio.branch_id
             WHERE branch_type_cd = 'InvFrmQ'

         )
SELECT
    obs.public_health_case_uid
     ,obs.observation_id
     ,obs.branch_id
     ,obs.branch_type_cd
     ,o.cd
     ,CASE
          WHEN obs.ovc_code = 'NI' THEN 'No Input'
          ELSE cvg.code_short_desc_txt
    END AS response
FROM InvFormQObservations obs
         LEFT JOIN dbo.nrt_observation o with (nolock) ON o.observation_uid = obs.branch_id
         LEFT JOIN dbo.codeset cs with (nolock) on cs.cd = o.cd
         LEFT JOIN nbs_srte.dbo.code_value_general cvg with (nolock)  on
    cvg.code_set_nm = cs.CODE_SET_NM and cvg.code = obs.ovc_code;