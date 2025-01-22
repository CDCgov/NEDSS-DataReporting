CREATE OR ALTER PROCEDURE dbo.sp_place_event @id_list nvarchar(max)
AS
BEGIN

    BEGIN TRY

        DECLARE @batch_id BIGINT;
        SET @batch_id = cast((format(getdate(), 'yyMMddHHmmss')) as bigint);

        INSERT INTO [rdb_modern].[dbo].[job_flow_log]
        (batch_id
        ,[Dataflow_Name]
        ,[package_Name]
        ,[Status_Type]
        ,[step_number]
        ,[step_name]
        ,[row_count]
        ,[Msg_Description1])
        VALUES (@batch_id
               ,'Place PRE-Processing Event'
               ,'NBS_ODSE.sp_place_event'
               ,'START'
               ,0
               ,LEFT('Pre ID-' + @id_list, 199)
               ,0
               ,LEFT(@id_list, 199));


        SELECT
            p.place_uid as 'place_uid',
            p.cd,
            case
                when (p.cd is not null or p.cd != '') then (select *
                                                            from dbo.fn_get_value_by_cvg(
                                                                    p.cd,
                                                                    'PLACE_TYPE'))
                end                                                                     as place_type_description,
            p.local_id as 'place_local_id',
            p.nm as 'place_name',
            NULLIF(p.description,'') as 'place_general_comments',
            p.add_time  as 'place_add_time',
            p.add_user_id  as 'place_add_user_id',
            p.last_chg_time as 'place_last_change_time',
            p.last_chg_user_id as 'place_last_chg_user_id',
            dbo.fn_get_record_status(p.record_status_cd) as 'place_record_status',
            p.record_status_time as 'place_record_status_time',
            p.status_cd  as 'place_status_cd',
            p.status_time as 'place_status_time',
            nested.entity                                  as 'place_entity',
            nested.address                               as 'place_address',
            nested.tele                                 as 'place_tele'
        FROM nbs_odse.dbo.Place p WITH (NOLOCK)
                 OUTER apply (SELECT *
                              FROM
                                  -- entity
                                  (SELECT (SELECT e.root_extension_txt as place_quick_code,
                                                  e.assigning_authority_cd
                                           FROM nbs_odse.dbo.Entity_id e WITH (NOLOCK)
                                           WHERE p.place_uid=e.entity_uid
                                             and e.type_cd = 'QEC'
                                           FOR json path, INCLUDE_NULL_VALUES) AS entity) AS entity,
                                  -- Place/ENTITY_LOCATOR_PARTICIPATION
                                  (SELECT (SELECT pl.postal_locator_uid as place_postal_uid,
                                                  pl.zip_cd as place_zip,
                                                  sc.code_desc_txt as place_state_desc,
                                                  pl.city_desc_txt as place_city,
                                                  pl.cntry_cd as place_country,
                                                  pl.street_addr1 as place_street_address_1,
                                                  pl.street_addr2 as place_street_address_2,
                                                  scc.code_desc_txt as place_county_desc,
                                                  cc.code_short_desc_txt as place_country_desc ,
                                                  pl.cnty_cd as place_county_code,
                                                  pl.state_cd as place_state_code,
                                                  elp.locator_desc_txt as place_address_comments,
                                                  elp.cd as place_elp_cd
                                           FROM nbs_odse.dbo.Entity_locator_participation elp WITH (NOLOCK)
                                                    LEFT OUTER JOIN nbs_odse.dbo.Postal_locator pl WITH (NOLOCK)
                                                                    ON elp.locator_uid = pl.postal_locator_uid
                                                    LEFT OUTER JOIN nbs_srte.dbo.State_code sc with (NOLOCK) ON sc.state_cd = pl.state_cd
                                                    LEFT OUTER JOIN nbs_srte.dbo.State_county_code_value scc with (NOLOCK)
                                                                    ON scc.code = pl.cnty_cd
                                                    LEFT OUTER JOIN nbs_srte.dbo.Country_code cc with (nolock) ON cc.CODE = pl.cntry_cd
                                           WHERE elp.entity_uid = p.place_uid
                                             AND elp.USE_CD='WP'
                                             AND elp.CD='PLC'
                                             AND elp.CLASS_CD='PST'
                                           FOR json path, INCLUDE_NULL_VALUES) AS address) AS address,
                                  -- Place/TELE
                                  (SELECT (SELECT p.place_uid,
                                                  tl.tele_locator_uid as place_tele_locator_uid,
                                                  tl.extension_txt as place_phone_ext,
                                                  tl.phone_nbr_txt as place_phone,
                                                  tl.email_address as place_email,
                                                  elp.locator_desc_txt as place_phone_comments,
                                                  elp.use_cd as tele_use_cd,
                                                  elp.cd as tele_cd,
                                                  case
                                                      when (elp.cd is not null or elp.cd != '') then (select *
                                                                                                      from dbo.fn_get_value_by_cvg(
                                                                                                              elp.cd,
                                                                                                              'EL_TYPE_TELE_PLC'))
                                                      end   						as place_tele_type,
                                                  case
                                                      when (elp.use_cd is not null or elp.use_cd != '') then (select *
                                                                                                              from dbo.fn_get_value_by_cvg(
                                                                                                                      elp.use_cd,
                                                                                                                      'EL_USE_TELE_PLC'))
                                                      end   						as place_tele_use
                                           FROM nbs_odse.dbo.Entity_locator_participation elp WITH (NOLOCK)
                                                    JOIN nbs_odse.dbo.Tele_locator tl WITH (NOLOCK)
                                                         ON elp.locator_uid = tl.tele_locator_uid
                                           WHERE elp.entity_uid = p.place_uid
                                             AND elp.class_cd = 'TELE'
                                           FOR json path, INCLUDE_NULL_VALUES) AS tele) AS tele) AS nested
        WHERE p.place_uid in (SELECT value FROM STRING_SPLIT(@id_list, ','));

        INSERT INTO [rdb_modern].[dbo].[job_flow_log] (batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
                                                      ,[Msg_Description1])
        VALUES (@batch_id
               ,'Place PRE-Processing Event'
               ,'NBS_ODSE.sp_place_event'
               ,'COMPLETE'
               ,0
               ,LEFT('Pre ID-' + @id_list, 199)
               ,0
               ,LEFT(@id_list, 199));

    END TRY
    BEGIN CATCH


        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        INSERT INTO [rdb_modern].[dbo].[job_flow_log] (batch_id
                                                      ,[Dataflow_Name]
                                                      ,[package_Name]
                                                      ,[Status_Type]
                                                      ,[step_number]
                                                      ,[step_name]
                                                      ,[row_count]
                                                      ,[Msg_Description1])
        VALUES (@batch_id
               ,'Place PRE-Processing Event'
               ,'NBS_ODSE.sp_place_event'
               ,'ERROR: ' + @ErrorMessage
               ,0
               ,LEFT('Pre ID-' + @id_list, 199)
               ,0
               ,LEFT(@id_list, 199));
        return @ErrorMessage;

    END CATCH

END;