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
                  ,o.cd
                  ,case WHEN o.cd IN ('CRS009',
                                      'CRS162',
                                      'DEM124',
                                      'DEM130',
                                      'DEM162',
                                      'DMH124',
                                      'DMH130',
                                      'DMH162',
                                      'INV117',
                                      'INV154',
                                      'LOC318',
                                      'LOC721',
                                      'NPH120',
                                      'NPP021',
                                      'ORD113') THEN 'state'
                        WHEN o.cd IN ('CRS163',
                                      'DEM125',
                                      'DEM131',
                                      'DEM165',
                                      'DMH125',
                                      'DMH131',
                                      'DMH165',
                                      'INV119',
                                      'INV156',
                                      'INV187',
                                      'LOC309',
                                      'LOC712',
                                      'NOT111',
                                      'NPH122',
                                      'NPP023',
                                      'ORD115',
                                      'PHC144',
                                      'SUM100') THEN 'county'
                        WHEN o.cd IN ('INV153','BMD276', 'CRS080','CRS098','CRS164','CRS165',
                                      'DEM126','DEM132','DEM167','HEP140','HEP142','HEP242','HEP255','NPP024',
                                      'ORD116','RUB146') THEN 'country'
                        WHEN o.cd IN ('INV107','GEO100','LAB168','MRB137','OBS1017','PHC127') THEN 'jurcode'
                        ELSE 'cvg_code' END AS label
             FROM
                 dbo.nrt_investigation_observation tnio with (nolock)
                     inner join dbo.nrt_observation_coded ovc with (nolock) ON ovc.observation_uid = tnio.branch_id
                     inner join dbo.nrt_observation o with (nolock) ON o.observation_uid = ovc.observation_uid
             WHERE branch_type_cd = 'InvFrmQ'

         )
SELECT
    obs.public_health_case_uid
     ,obs.observation_id
     ,obs.branch_id
     ,obs.branch_type_cd
     ,obs.cd
     ,CASE
          WHEN obs.ovc_code = 'NI' THEN 'No Input'
          WHEN label = 'cvg_code' THEN cvg.code_short_desc_txt
          WHEN label = 'country' THEN cc.code_short_desc_txt
          WHEN label = 'state' THEN sc.state_nm
          WHEN label = 'county' THEN sccv.code_desc_txt
          WHEN label = 'jurcode' THEN jc.code_short_desc_txt
          ELSE NULL
    END AS response
     ,CASE
          WHEN label = 'country' THEN cc.code
          WHEN label = 'state' THEN sc.state_cd
          WHEN label = 'county' THEN sccv.code
          WHEN label = 'jurcode' THEN jc.code
          ELSE NULL
    END AS response_cd,
    label
FROM InvFormQObservations obs
         LEFT JOIN dbo.codeset cs with (nolock) on cs.cd = obs.cd
         LEFT JOIN nbs_srte.dbo.code_value_general cvg with (nolock)  on
    cvg.code_set_nm = cs.CODE_SET_NM and cvg.code = obs.ovc_code
         LEFT JOIN nbs_srte.dbo.Country_code cc with (nolock) on cc.code = obs.ovc_code
         LEFT JOIN nbs_srte.dbo.State_code sc with (nolock) on sc.state_cd = obs.ovc_code
         LEFT JOIN nbs_srte.dbo.State_county_code_value sccv with (nolock) on sccv.code = obs.ovc_code
         LEFT JOIN nbs_srte.dbo.Jurisdiction_code jc with (nolock) on jc.code = obs.ovc_code
;