/*==============================================================================
    Procedure:   dbo.sp_observation_event
    Purpose:     Pre-processing / extraction step for the Observation data flow.
                 Given a comma-delimited list of observation_uid values, this
                 procedure:
                   1. Logs a START event to the job flow log.
                   2. Walks the act_relationship graph (up to 4 hops) to find
                      related/follow-up acts and associated PHC (case) uids.
                   3. Resolves person participations (with name/ID enrichment)
                      tied to each origin observation.
                   4. Returns one row per requested observation, enriched with
                      nested JSON blocks for participations, related acts,
                      identifiers, and observation values (text/coded/date/
                      numeric).
                   5. Logs a COMPLETE event to the job flow log.
                 On failure, rolls back any open transaction, logs an ERROR
                 event with full error detail, and returns the error message
                 to the caller.

    Parameters:
        @obs_id_list  NVARCHAR(MAX) - Comma-separated list of observation_uid
                                       values to process (e.g. '1001,1002,1003').

    Notes:
        - Uses NOLOCK hints throughout; this is a read-oriented reporting/ETL
          query and is expected to tolerate dirty reads for throughput.
        - Recursive CTE (related_acts) is capped at 4 hops via
          OPTION (MAXRECURSION 4) to prevent runaway recursion on cyclic or
          deep relationship graphs.
        - Nested SELECT ... FOR JSON PATH blocks are used to shape related
          child data (participations, ids, values) as JSON columns per row,
          avoiding a separate round trip per child entity type.
==============================================================================*/

IF EXISTS (
    SELECT *
    FROM sysobjects
    WHERE id = OBJECT_ID(N'[dbo].[sp_observation_event]')
      AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_observation_event];
END
GO

CREATE PROCEDURE [dbo].[sp_observation_event]
    @obs_id_list NVARCHAR(MAX)
AS
BEGIN

    BEGIN TRY

        -----------------------------------------------------------------------
        -- Generate a unique batch id for this run, based on current timestamp
        -- (format: yyMMddHHmmssffff). Used to correlate log rows for this run.
        -----------------------------------------------------------------------
        DECLARE @batch_id BIGINT;
        SET @batch_id = CAST(FORMAT(GETDATE(), 'yyMMddHHmmssffff') AS BIGINT);

        -----------------------------------------------------------------------
        -- Log START event for this batch, capturing the input id list
        -- (truncated to 199 chars to fit the log column).
        -----------------------------------------------------------------------
        INSERT INTO [dbo].[job_flow_log] (
            batch_id,
            [Dataflow_Name],
            [package_Name],
            [Status_Type],
            [step_number],
            [step_name],
            [row_count],
            [Msg_Description1]
        )
        VALUES (
            @batch_id,
            'Observation PRE-Processing Event',
            'sp_observation_event',
            'START',
            0,
            LEFT('Pre ID-' + @obs_id_list, 199),
            0,
            LEFT(@obs_id_list, 199)
        );

        WITH
            -------------------------------------------------------------------
            -- base_ids: parse the incoming CSV parameter into a set of
            -- observation_uid values to drive the rest of the query.
            -------------------------------------------------------------------
            base_ids AS (
                SELECT
                    CAST(value AS BIGINT) AS observation_uid
                FROM STRING_SPLIT(@obs_id_list, ',')
            ),

            -------------------------------------------------------------------
            -- related_acts: recursively walk act_relationship upstream from
            -- each base observation (target -> source) to find every act that
            -- feeds into it, up to 4 hops deep (bounded by MAXRECURSION below).
            -- hop_level tracks recursion depth for traceability/debugging.
            -------------------------------------------------------------------
            related_acts AS (
                -- Anchor: direct relationships pointing at the base observation
                SELECT
                    b.observation_uid AS origin_observation_uid,
                    ar.source_act_uid,
                    ar.record_status_cd,
                    1 AS hop_level
                FROM base_ids b
                JOIN nbs_odse.dbo.act_relationship ar WITH (NOLOCK)
                    ON ar.target_act_uid = b.observation_uid
                WHERE ar.source_act_uid IS NOT NULL

                UNION ALL

                -- Recursive step: follow the chain one more hop upstream
                SELECT
                    ra.origin_observation_uid,
                    ar.source_act_uid,
                    ar.record_status_cd,
                    ra.hop_level + 1
                FROM related_acts ra
                JOIN nbs_odse.dbo.act_relationship ar WITH (NOLOCK)
                    ON ar.target_act_uid = ra.source_act_uid
                WHERE ra.hop_level < 4
                  AND ar.source_act_uid IS NOT NULL
            ),

            -------------------------------------------------------------------
            -- resolved_followups: distinct set of ACTIVE upstream acts per
            -- origin observation, used later to pull follow-up observation
            -- details (result_observation_uid, cd, etc.).
            -------------------------------------------------------------------
            resolved_followups AS (
                SELECT DISTINCT
                    origin_observation_uid,
                    source_act_uid
                FROM related_acts
                WHERE record_status_cd = 'ACTIVE'
            ),

            -------------------------------------------------------------------
            -- resolved_phc_uids: for each base observation, aggregate the
            -- uids of any linked CASE-class acts (via MorbReport/LabReport
            -- relationship types) into a comma-separated list. Represents the
            -- "public health case" uids associated with the observation.
            -------------------------------------------------------------------
            resolved_phc_uids AS (
                SELECT
                    b.observation_uid AS origin_observation_uid,
                    STRING_AGG(ar.target_act_uid, ',') AS associated_phc_uids
                FROM base_ids b
                JOIN nbs_odse.dbo.Act_relationship ar WITH (NOLOCK)
                    ON ar.source_act_uid = b.observation_uid
                WHERE ar.type_cd IN ('MorbReport', 'LabReport')
                  AND ar.target_class_cd = 'CASE'
                GROUP BY b.observation_uid
            ),

            -------------------------------------------------------------------
            -- relevant_persons: the distinct set of person_uids actually
            -- referenced by ACTIVE participations on this batch's
            -- observations. Used to pre-filter the person enrichment lookup
            -- below so the entity_id/role fan-out joins only run for
            -- persons relevant to this call, instead of the whole person
            -- table (PERFORMANCE: avoids full-table enrichment + fan-out).
            -------------------------------------------------------------------
            relevant_persons AS (
                SELECT DISTINCT
                    p.subject_entity_uid AS person_uid
                FROM base_ids b
                JOIN nbs_odse.dbo.participation p WITH (NOLOCK)
                    ON p.act_uid = b.observation_uid
                WHERE p.record_status_cd = 'ACTIVE'
            ),

            -------------------------------------------------------------------
            -- resolved_person_participations: for each base observation,
            -- resolve the ACTIVE person participation(s) plus enriched person
            -- attributes (name, identifiers, role) via an inline lookup that
            -- joins person -> person_name -> entity_id -> role -> code value
            -- lookup (for the ID type description).
            -------------------------------------------------------------------
            resolved_person_participations AS (
                SELECT
                    p.act_uid                          AS origin_observation_uid,
                    p.act_uid                          AS [act_uid],
                    p.type_cd                          AS [type_cd],
                    p.subject_entity_uid                AS [entity_id],
                    p.subject_class_cd                  AS [subject_class_cd],
                    p.record_status_cd                  AS [participation_record_status],
                    p.last_chg_time                     AS [participation_last_change_time],
                    p.type_desc_txt                     AS [type_desc_txt],
                    person.person_cd,
                    person.person_parent_uid,
                    person.person_record_status,
                    person.person_last_chg_time,
                    person.person_id_val,
                    person.person_id_type,
                    person.person_id_assign_auth_cd,
                    person.entity_record_status_cd,
                    person.person_id_type_desc,
                    person.last_nm,
                    person.first_nm,
                    person.role_cd,
                    person.subject_class_cd             AS [role_subject_class_cd],
                    person.scoping_class_cd             AS [role_scoping_class_cd]
                FROM base_ids b
                JOIN nbs_odse.dbo.participation p WITH (NOLOCK)
                    ON p.act_uid = b.observation_uid
                JOIN (
                    -- Inline person lookup: base person record enriched with
                    -- name (escaped for JSON safety), external identifier,
                    -- id-type description, and role/scoping class.
                    SELECT
                        person.[person_parent_uid],
                        person.cd                                              AS [person_cd],
                        person.record_status_cd                                AS [person_record_status],
                        person.last_chg_time                                   AS [person_last_chg_time],
                        e.root_extension_txt                                   AS [person_id_val],
                        e.type_cd                                              AS [person_id_type],
                        e.assigning_authority_cd                               AS [person_id_assign_auth_cd],
                        e.record_status_cd                                     AS [entity_record_status_cd],
                        cvg.code_short_desc_txt                                AS [person_id_type_desc],
                        STRING_ESCAPE(REPLACE(pn.last_nm, '-', ' '), 'json')   AS [last_nm],
                        STRING_ESCAPE(pn.first_nm, 'json')                     AS [first_nm],
                        person.person_uid,
                        r.cd                                                   AS [role_cd],
                        r.subject_class_cd,
                        r.scoping_class_cd
                    FROM nbs_odse.dbo.person WITH (NOLOCK)
                    JOIN nbs_odse.dbo.person_name pn WITH (NOLOCK)
                        ON pn.person_uid = person.person_uid
                    LEFT JOIN nbs_odse.dbo.entity_id e WITH (NOLOCK)
                        ON e.entity_uid = person.person_uid
                    LEFT JOIN nbs_odse.dbo.role r WITH (NOLOCK)
                        ON person.person_uid = r.subject_entity_uid
                    LEFT JOIN nbs_srte.dbo.code_value_general AS cvg WITH (NOLOCK)
                        ON e.type_cd = cvg.code
                       AND cvg.code_set_nm = 'EI_TYPE'
                    -- PERFORMANCE FIX: restrict the enrichment lookup (and the
                    -- entity_id/role fan-out above) to only the persons
                    -- actually referenced by this batch, instead of computing
                    -- it for every person row in the table before the outer
                    -- JOIN below filters it down. This is a pure push-down of
                    -- a filter the outer join already applies, so it does not
                    -- change which rows/columns are returned.
                    WHERE person.person_uid IN (SELECT person_uid FROM relevant_persons)
                ) person
                    ON person.person_uid = p.subject_entity_uid
                WHERE p.record_status_cd = 'ACTIVE'
            )

        -----------------------------------------------------------------------
        -- Main result set: one row per requested observation, joined to its
        -- act header and interpretation, with all related child data shaped
        -- as JSON via OUTER APPLY sub-selects (one per related entity type).
        -----------------------------------------------------------------------
        SELECT
            act.act_uid,
            act.class_cd,
            act.mood_cd,
            oi.interpretation_cd,
            oi.interpretation_desc_txt,
            o.observation_uid,
            o.obs_domain_cd_st_1,
            o.cd_desc_txt,
            o.record_status_cd,
            o.program_jurisdiction_oid,
            o.prog_area_cd,
            o.jurisdiction_cd,
            o.pregnant_ind_cd,
            o.local_id                                                   AS local_id,
            o.activity_to_time,
            o.effective_from_time,
            o.rpt_to_state_time,
            o.electronic_ind,
            o.version_ctrl_nbr,
            o.ctrl_cd_display_form,
            o.processing_decision_cd,
            o.cd,
            o.shared_ind,
            o.status_cd,
            o.cd_system_cd,
            o.cd_system_desc_txt,
            o.ctrl_cd_user_defined_1,
            o.alt_cd,
            o.alt_cd_desc_txt,
            o.alt_cd_system_cd,
            o.alt_cd_system_desc_txt,
            o.method_cd,
            o.method_desc_txt,
            o.target_site_cd,
            o.target_site_desc_txt,
            o.txt,
            o.priority_cd,
            o.add_user_id,
            -- Resolve add_user_id to a display name only when populated (>0)
            CASE
                WHEN o.add_user_id > 0
                    THEN (SELECT * FROM dbo.fn_get_user_name(o.add_user_id))
            END AS add_user_name,
            o.last_chg_user_id,
            -- Resolve last_chg_user_id to a display name only when populated (>0)
            CASE
                WHEN o.last_chg_user_id > 0
                    THEN (SELECT * FROM dbo.fn_get_user_name(o.last_chg_user_id))
            END AS last_chg_user_name,
            o.add_time                                                   AS add_time,
            o.last_chg_time                                              AS last_chg_time,
            o.record_status_time,
            o.status_time,
            o.activity_from_time,
            nesteddata.person_participations,
            nesteddata.organization_participations,
            nesteddata.material_participations,
            nesteddata.followup_observations,
            nesteddata.parent_observations,
            nesteddata.act_ids,
            nesteddata.edx_ids,
            nesteddata.obs_reason,
            nesteddata.obs_txt,
            nesteddata.obs_code,
            nesteddata.obs_date,
            nesteddata.obs_num,
            nesteddata.associated_phc_uids
        FROM nbs_odse.dbo.Observation o WITH (NOLOCK)
        JOIN nbs_odse.dbo.act WITH (NOLOCK)
            ON o.observation_uid = act.act_uid
        LEFT OUTER JOIN nbs_odse.dbo.observation_interp oi WITH (NOLOCK)
            ON o.observation_uid = oi.observation_uid
        OUTER APPLY (
            SELECT *
            FROM (
                ---------------------------------------------------------------
                -- associated_phc_uids: comma-separated list of linked case
                -- (PHC) uids resolved above in resolved_phc_uids.
                ---------------------------------------------------------------
                SELECT (
                    SELECT associated_phc_uids
                    FROM resolved_phc_uids rp
                    WHERE rp.origin_observation_uid = o.observation_uid
                ) AS associated_phc_uids,

                ---------------------------------------------------------------
                -- followup_observations: JSON array of downstream/follow-up
                -- observations reachable via the recursive relationship walk.
                ---------------------------------------------------------------
                (
                    SELECT (
                        SELECT
                            o2.observation_uid       AS [result_observation_uid],
                            o2.cd                     AS [cd],
                            o2.cd_desc_txt            AS [cd_desc_txt],
                            o2.obs_domain_cd_st_1     AS [domain_cd_st_1]
                        FROM resolved_followups rf
                        JOIN nbs_odse.dbo.observation o2 WITH (NOLOCK)
                            ON o2.observation_uid = rf.source_act_uid
                        WHERE rf.origin_observation_uid = o.observation_uid
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    ) AS followup_observations
                ) AS followup_observations,

                ---------------------------------------------------------------
                -- parent_observations: JSON array of directly linked parent
                -- observation acts (one hop, ACTIVE, class 'OBS').
                ---------------------------------------------------------------
                (
                    SELECT (
                        SELECT
                            ar.type_cd                AS [parent_type_cd],
                            ar.source_act_uid          AS [observation_uid],
                            o2.observation_uid         AS [parent_uid],
                            o2.cd                      AS [parent_cd],
                            o2.cd_desc_txt             AS [parent_cd_desc_txt],
                            o2.obs_domain_cd_st_1      AS [parent_domain_cd_st_1]
                        FROM nbs_odse.dbo.act_relationship ar WITH (NOLOCK)
                        JOIN nbs_odse.dbo.observation o2 WITH (NOLOCK)
                            ON ar.target_act_uid = o2.observation_uid
                        WHERE ar.source_act_uid = o.observation_uid
                          AND ar.target_class_cd = 'OBS'
                          AND ar.record_status_cd = 'ACTIVE'
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    ) AS parent_observations
                ) AS parent_observations,

                ---------------------------------------------------------------
                -- person_participations: JSON array of enriched ACTIVE person
                -- participations resolved above in resolved_person_participations.
                ---------------------------------------------------------------
                (
                    SELECT (
                        SELECT
                            rpp.[act_uid],
                            rpp.[type_cd],
                            rpp.[entity_id],
                            rpp.[subject_class_cd],
                            rpp.[participation_record_status],
                            rpp.[participation_last_change_time],
                            rpp.[type_desc_txt],
                            rpp.person_cd,
                            rpp.person_parent_uid,
                            rpp.person_record_status,
                            rpp.person_last_chg_time,
                            rpp.person_id_val,
                            rpp.person_id_type,
                            rpp.person_id_assign_auth_cd,
                            rpp.entity_record_status_cd,
                            rpp.person_id_type_desc,
                            rpp.last_nm,
                            rpp.first_nm,
                            rpp.role_cd,
                            rpp.[role_subject_class_cd],
                            rpp.[role_scoping_class_cd]
                        FROM resolved_person_participations rpp
                        WHERE rpp.origin_observation_uid = o.observation_uid
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    ) AS person_participations
                ) AS person_participations,

                ---------------------------------------------------------------
                -- organization_participations: JSON array of ACTIVE
                -- organization participations tied directly to this observation.
                ---------------------------------------------------------------
                (
                    SELECT (
                        SELECT
                            p.act_uid                              AS [act_uid],
                            p.type_cd                              AS [type_cd],
                            p.subject_entity_uid                    AS [entity_id],
                            p.subject_class_cd                      AS [subject_class_cd],
                            p.record_status_cd                      AS [record_status],
                            p.type_desc_txt                         AS [type_desc_txt],
                            p.last_chg_time                         AS [last_change_time],
                            STRING_ESCAPE(org.display_nm, 'json')   AS [name],
                            org.last_chg_time                       AS [org_last_change_time]
                        FROM nbs_odse.dbo.participation p WITH (NOLOCK)
                        JOIN nbs_odse.dbo.organization org WITH (NOLOCK)
                            ON org.organization_uid = p.subject_entity_uid
                        WHERE p.act_uid = o.observation_uid
                          AND p.record_status_cd = 'ACTIVE'
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    ) AS organization_participations
                ) AS organization_participations,

                ---------------------------------------------------------------
                -- material_participations: JSON array of material (e.g.
                -- specimen) participations tied to this observation. Note:
                -- unlike other participation blocks, this is not filtered to
                -- ACTIVE-only records.
                ---------------------------------------------------------------
                (
                    SELECT (
                        SELECT
                            p.act_uid                             AS [act_uid],
                            p.type_cd                             AS [type_cd],
                            p.subject_entity_uid                   AS [entity_id],
                            p.subject_class_cd                     AS [subject_class_cd],
                            p.record_status_cd                     AS [record_status],
                            p.type_desc_txt                        AS [type_desc_txt],
                            p.last_chg_time                        AS [last_chg_time],
                            STRING_ESCAPE(m.cd, 'json')            AS [material_cd],
                            m.nm                                    AS [material_nm],
                            m.description                           AS [material_details],
                            m.qty                                   AS [material_collection_vol],
                            m.qty_unit_cd                           AS [material_collection_vol_unit],
                            m.cd_desc_txt                           AS [material_desc],
                            m.risk_cd                               AS [risk_cd],
                            m.risk_desc_txt                         AS [risk_desc_txt]
                        FROM nbs_odse.dbo.participation p WITH (NOLOCK)
                        JOIN nbs_odse.dbo.material m WITH (NOLOCK)
                            ON m.material_uid = p.subject_entity_uid
                        WHERE p.act_uid = o.observation_uid
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    ) AS material_participations
                ) AS material_participations,

                ---------------------------------------------------------------
                -- act_ids: JSON array of alternate identifiers assigned to
                -- this act (e.g. accession numbers, external ids).
                ---------------------------------------------------------------
                (
                    SELECT (
                        SELECT
                            act_uid                                     AS [id],
                            act_id_seq                                  AS [act_id_seq],
                            record_status_cd                            AS [record_status],
                            STRING_ESCAPE(root_extension_txt, 'json')   AS [root_extension_txt],
                            type_cd                                     AS [type_cd],
                            type_desc_txt                               AS [type_desc_txt],
                            last_chg_time                               AS [act_last_change_time]
                        FROM nbs_odse.dbo.act_id WITH (NOLOCK)
                        WHERE act_uid = o.observation_uid
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    ) AS act_ids
                ) AS act_ids,

                ---------------------------------------------------------------
                -- edx_ids: JSON array of linked EDX (electronic document
                -- exchange) document references for this act.
                ---------------------------------------------------------------
                (
                    SELECT (
                        SELECT
                            EDX_Document_uid   AS [edx_document_uid],
                            act_uid             AS [edx_act_uid],
                            add_time            AS [edx_add_time]
                        FROM nbs_odse.dbo.EDX_Document WITH (NOLOCK)
                        WHERE act_uid = o.observation_uid
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    ) AS edx_ids
                ) AS edx_ids,

                ---------------------------------------------------------------
                -- obs_reason: JSON array of coded reasons associated with
                -- this observation.
                ---------------------------------------------------------------
                (
                    SELECT (
                        SELECT
                            obr.observation_uid,
                            obr.reason_cd,
                            obr.reason_desc_txt
                        FROM nbs_odse.dbo.observation_reason obr WITH (NOLOCK)
                        WHERE obr.observation_uid = o.observation_uid
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    ) AS obs_reason
                ) AS obs_reason,

                ---------------------------------------------------------------
                -- obs_txt: JSON array of free-text observation values, with
                -- embedded CR/LF stripped to keep JSON output clean.
                ---------------------------------------------------------------
                (
                    SELECT (
                        SELECT
                            ot.observation_uid,
                            ot.obs_value_txt_seq                                          AS [ovt_seq],
                            ot.txt_type_cd                                                AS [ovt_txt_type_cd],
                            REPLACE(REPLACE(ot.value_txt, CHAR(13), ' '), CHAR(10), ' ')   AS [ovt_value_txt]
                        FROM nbs_odse.dbo.obs_value_txt ot WITH (NOLOCK)
                        WHERE ot.observation_uid = o.observation_uid
                          AND ot.value_txt IS NOT NULL
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    ) AS obs_txt
                ) AS obs_txt,

                ---------------------------------------------------------------
                -- obs_code: JSON array of coded observation values (e.g.
                -- LOINC/SNOMED result codes) for this observation.
                ---------------------------------------------------------------
                (
                    SELECT (
                        SELECT
                            ob.observation_uid,
                            STRING_ESCAPE(ob.display_name, 'json')   AS [ovc_display_name],
                            ob.code                                   AS [ovc_code],
                            ob.code_system_cd                         AS [ovc_code_system_cd],
                            ob.code_system_desc_txt                   AS [ovc_code_system_desc_txt],
                            ob.alt_cd                                 AS [ovc_alt_cd],
                            ob.alt_cd_desc_txt                        AS [ovc_alt_cd_desc_txt],
                            ob.alt_cd_system_cd                       AS [ovc_alt_cd_system_cd],
                            ob.alt_cd_system_desc_txt                 AS [ovc_alt_cd_system_desc_txt]
                        FROM nbs_odse.dbo.obs_value_coded ob WITH (NOLOCK)
                        WHERE ob.observation_uid = o.observation_uid
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    ) AS obs_code
                ) AS obs_code,

                ---------------------------------------------------------------
                -- obs_date: JSON array of date-range observation values.
                ---------------------------------------------------------------
                (
                    SELECT (
                        SELECT
                            od.observation_uid,
                            od.from_time              AS [ovd_from_date],
                            od.to_time                AS [ovd_to_date],
                            od.obs_value_date_seq     AS [ovd_seq]
                        FROM nbs_odse.dbo.obs_value_date od WITH (NOLOCK)
                        WHERE od.observation_uid = o.observation_uid
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    ) AS obs_date
                ) AS obs_date,

                ---------------------------------------------------------------
                -- obs_num: JSON array of numeric observation values,
                -- including comparator/range info. low_range/high_range are
                -- truncated to 20 chars as a defensive length cap.
                ---------------------------------------------------------------
                (
                    SELECT (
                        SELECT
                            ovn.observation_uid,
                            ovn.comparator_cd_1                    AS [ovn_comparator_cd_1],
                            ovn.numeric_value_1                    AS [ovn_numeric_value_1],
                            ovn.separator_cd                       AS [ovn_separator_cd],
                            ovn.numeric_value_2                    AS [ovn_numeric_value_2],
                            ovn.numeric_unit_cd                    AS [ovn_numeric_unit_cd],
                            SUBSTRING(ovn.low_range, 1, 20)        AS [ovn_low_range],
                            SUBSTRING(ovn.high_range, 1, 20)       AS [ovn_high_range],
                            ovn.obs_value_numeric_seq              AS [ovn_seq]
                        FROM nbs_odse.dbo.obs_value_numeric ovn WITH (NOLOCK)
                        WHERE ovn.observation_uid = o.observation_uid
                        FOR JSON PATH, INCLUDE_NULL_VALUES
                    ) AS obs_num
                ) AS obs_num
            ) AS nesteddata
        ) AS nesteddata
        WHERE o.observation_uid IN (SELECT observation_uid FROM base_ids)
        OPTION (MAXRECURSION 4);

        -- select * from dbo.Observation_Dim_Event;  -- (left for reference / debugging)

        -----------------------------------------------------------------------
        -- Log COMPLETE event for this batch.
        -----------------------------------------------------------------------
        INSERT INTO [dbo].[job_flow_log] (
            batch_id,
            [Dataflow_Name],
            [package_Name],
            [Status_Type],
            [step_number],
            [step_name],
            [row_count],
            [Msg_Description1]
        )
        VALUES (
            @batch_id,
            'Observation PRE-Processing Event',
            'sp_observation_event',
            'COMPLETE',
            0,
            LEFT('Pre ID-' + @obs_id_list, 199),
            0,
            LEFT(@obs_id_list, 199)
        );

    END TRY
    BEGIN CATCH

        -- Roll back any open transaction before logging/returning the error.
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Build a detailed, multi-line error message capturing the standard
        -- SQL Server error functions for troubleshooting.
        DECLARE @FullErrorMessage VARCHAR(8000) =
            'Error Number: '   + CAST(ERROR_NUMBER()   AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error State: '    + CAST(ERROR_STATE()    AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Line: '     + CAST(ERROR_LINE()     AS VARCHAR(10)) + CHAR(13) + CHAR(10) +
            'Error Message: '  + ERROR_MESSAGE();

        -- Log the ERROR event, including the full error detail, then
        -- surface the error message back to the caller.
        INSERT INTO [dbo].[job_flow_log] (
            batch_id,
            [Dataflow_Name],
            [package_Name],
            [Status_Type],
            [step_number],
            [step_name],
            [row_count],
            [Msg_Description1],
            [Error_Description]
        )
        VALUES (
            @batch_id,
            'Observation PRE-Processing Event',
            'sp_observation_event',
            'ERROR',
            0,
            'Observation PRE-Processing Event',
            0,
            LEFT(@obs_id_list, 199),
            @FullErrorMessage
        );

        RETURN @FullErrorMessage;

    END CATCH

END;
