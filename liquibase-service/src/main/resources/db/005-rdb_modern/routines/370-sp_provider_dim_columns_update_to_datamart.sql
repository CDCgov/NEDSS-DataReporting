IF EXISTS (SELECT * FROM sysobjects WHERE  id = object_id(N'[dbo].[sp_provider_dim_columns_update_to_datamart]')
	AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
BEGIN
    DROP PROCEDURE [dbo].[sp_provider_dim_columns_update_to_datamart]
END
GO 
CREATE PROCEDURE [dbo].[sp_provider_dim_columns_update_to_datamart] @batch_id bigint, @debug bit = 'false'
AS
BEGIN
 /*
     * [Description]
     * This stored procedure updates specific patient fields available in the datamarts listed below
     * 1. MORBIDITY_REPORT_DATAMART
     * 2. STD_HIV_DATAMART
     * 3. HEP100
     * 4. TB_DATAMART
     * 5. TB_HIV_DATAMART
     * 6. AGGREGATE_REPORT_DATAMART
*/
    declare @rowcount bigint;
    declare @proc_step_no float = 0;
    declare @proc_step_name varchar(200) = '';
    declare @dataflow_name varchar(200) = 'Provider POST-Processing';
    declare @package_name varchar(200) = 'sp_provider_delta_update';

    ---------------------------------------------------------------------------------------------------------------------------------

    SET @proc_step_name=' Update Provider attributes in MORBIDITY_REPORT_DATAMART for PROVIDER';
    SET @proc_step_no = 5.5;


    select
        h.MORBIDITY_REPORT_KEY,
        d.INVESTIGATION_KEY,
        g.*
    into #INVESTIGATION_PROVIDER_MAPPING_FOR_MRD
    from
        dbo.MORBIDITY_REPORT_EVENT d with (nolock)
    inner join dbo.MORBIDITY_REPORT_DATAMART h with (nolock)
        on d.MORB_RPT_KEY  = h.MORBIDITY_REPORT_KEY
    inner join #PROVIDER_UPDATE_LIST g with (nolock)
        on g.PROVIDER_KEY = d.PHYSICIAN_KEY
    where datamart_update+morbidity_datamart_update >= 1;


    if @debug = 'true'
        select '#INVESTIGATION_PROVIDER_MAPPING_FOR_MRD', * from #INVESTIGATION_PROVIDER_MAPPING_FOR_MRD;

    IF EXISTS (SELECT 1 FROM #INVESTIGATION_PROVIDER_MAPPING_FOR_MRD)
    BEGIN
        update dbo.MORBIDITY_REPORT_DATAMART 
        set 
        PROVIDER_LAST_NAME = tmp.PROVIDER_LAST_NAME,
        PROVIDER_FIRST_NAME = tmp.PROVIDER_FIRST_NAME,
        PROVIDER_STREET_ADDR_1 = tmp.PROVIDER_STREET_ADDRESS_1,
        PROVIDER_STREET_ADDR_2 = tmp.PROVIDER_STREET_ADDRESS_2,
        PROVIDER_CITY = tmp.PROVIDER_CITY,
        PROVIDER_STATE = tmp.PROVIDER_STATE,
        PROVIDER_ZIP = tmp.PROVIDER_ZIP,
        PROVIDER_PHONE = tmp.PROVIDER_PHONE_WORK,
        PROVIDER_PHONE_EXT = tmp.PROVIDER_PHONE_EXT_WORK
        from  
            #INVESTIGATION_PROVIDER_MAPPING_FOR_MRD tmp
        where 
            dbo.MORBIDITY_REPORT_DATAMART.MORBIDITY_REPORT_KEY = tmp.MORBIDITY_REPORT_KEY
            ;
    END

    set @rowcount=@@rowcount;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);

    ---------------------------------------------------------------------------------------------------------------------------------
    
    SET @proc_step_name=' Update Provider attributes in MORBIDITY_REPORT_DATAMART for REPORTER';
    SET @proc_step_no = 5.6;

    select
        h.MORBIDITY_REPORT_KEY,
        d.INVESTIGATION_KEY,
        g.*
    into #INVESTIGATION_REPORTER_MAPPING_FOR_MRD
    from
    dbo.MORBIDITY_REPORT_EVENT d with (nolock)
    inner join dbo.MORBIDITY_REPORT_DATAMART h with (nolock)
        on d.MORB_RPT_KEY  = h.MORBIDITY_REPORT_KEY
    inner join #PROVIDER_UPDATE_LIST g with (nolock)
        on g.PROVIDER_KEY = d.REPORTER_KEY
    where datamart_update+morbidity_datamart_update >= 1;


    if @debug = 'true'
        select '#INVESTIGATION_REPORTER_MAPPING_FOR_MRD', * from #INVESTIGATION_REPORTER_MAPPING_FOR_MRD;
    
    IF EXISTS (SELECT 1 FROM  #INVESTIGATION_REPORTER_MAPPING_FOR_MRD)
    BEGIN
        update dbo.MORBIDITY_REPORT_DATAMART 
        set 
        REPORTER_LAST_NAME = tmp.PROVIDER_LAST_NAME,
        REPORTER_FIRST_NAME = tmp.PROVIDER_FIRST_NAME,
        REPORTER_STREET_ADDR_1 = tmp.PROVIDER_STREET_ADDRESS_1,
        REPORTER_STREET_ADDR_2 = tmp.PROVIDER_STREET_ADDRESS_2,
        REPORTER_CITY = tmp.PROVIDER_CITY,
        REPORTER_STATE = tmp.PROVIDER_STATE,
        REPORTER_ZIP = tmp.PROVIDER_ZIP,
        REPORTER_PHONE = tmp.PROVIDER_PHONE_WORK,
        REPORTER_PHONE_EXT = tmp.PROVIDER_PHONE_EXT_WORK
        from  
            #INVESTIGATION_REPORTER_MAPPING_FOR_MRD tmp
        where
            dbo.MORBIDITY_REPORT_DATAMART.MORBIDITY_REPORT_KEY = tmp.MORBIDITY_REPORT_KEY
            ;
    END

    set @rowcount=@@rowcount;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);


    ---------------------------------------------------------------------------------------------------------------------------------

    SET @proc_step_name=' Update Provider attributes in STD_HIV_DATAMART';
    SET @proc_step_no = 5.7;

    IF EXISTS (SELECT 1 from dbo.STD_HIV_DATAMART dm with (nolock) 
        INNER JOIN #PROVIDER_UPDATE_LIST tmp 
        ON std_hiv_datamart_update >= 1
        AND (
            dm.INVESTIGATOR_CLOSED_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_CURRENT_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_DISP_FL_FUP_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_FL_FUP_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_INIT_INTRVW_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_INIT_FL_FUP_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_INITIAL_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_INTERVIEW_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_SUPER_CASE_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_SUPER_FL_FUP_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_SURV_KEY = tmp.PROVIDER_KEY
        )
    )
    BEGIN

        UPDATE dm
        SET 
        INVESTIGATOR_CLOSED_QC = CASE 
            WHEN dm.INVESTIGATOR_CLOSED_KEY = tmp.PROVIDER_KEY AND std_hiv_datamart_update >= 1
                    THEN tmp.PROVIDER_QUICK_CODE 
            ELSE dm.INVESTIGATOR_CLOSED_QC 
        END,
        INVESTIGATOR_CURRENT_QC = CASE 
            WHEN dm.INVESTIGATOR_CURRENT_KEY = tmp.PROVIDER_KEY AND std_hiv_datamart_update >= 1
                    THEN tmp.PROVIDER_QUICK_CODE 
            ELSE dm.INVESTIGATOR_CURRENT_QC 
        END,
        INVESTIGATOR_DISP_FL_FUP_QC = CASE 
            WHEN dm.INVESTIGATOR_DISP_FL_FUP_KEY = tmp.PROVIDER_KEY AND std_hiv_datamart_update >= 1
                    THEN tmp.PROVIDER_QUICK_CODE 
            ELSE dm.INVESTIGATOR_DISP_FL_FUP_QC 
        END,
        INVESTIGATOR_FL_FUP_QC = CASE 
            WHEN dm.INVESTIGATOR_FL_FUP_KEY = tmp.PROVIDER_KEY AND std_hiv_datamart_update >= 1
                    THEN tmp.PROVIDER_QUICK_CODE 
            ELSE dm.INVESTIGATOR_FL_FUP_QC 
        END,
        INVESTIGATOR_INIT_INTRVW_QC = CASE 
            WHEN dm.INVESTIGATOR_INIT_INTRVW_KEY = tmp.PROVIDER_KEY AND std_hiv_datamart_update >= 1
                    THEN tmp.PROVIDER_QUICK_CODE 
            ELSE dm.INVESTIGATOR_INIT_INTRVW_QC 
        END,
        INVESTIGATOR_INIT_FL_FUP_QC = CASE 
            WHEN dm.INVESTIGATOR_INIT_FL_FUP_KEY = tmp.PROVIDER_KEY AND std_hiv_datamart_update >= 1
                    THEN tmp.PROVIDER_QUICK_CODE 
            ELSE dm.INVESTIGATOR_INIT_FL_FUP_QC 
        END,
        INVESTIGATOR_INITIAL_QC = CASE 
            WHEN dm.INVESTIGATOR_INITIAL_KEY = tmp.PROVIDER_KEY AND std_hiv_datamart_update >= 1
                    THEN tmp.PROVIDER_QUICK_CODE 
            ELSE dm.INVESTIGATOR_INITIAL_QC 
        END,
        INVESTIGATOR_INTERVIEW_QC = CASE 
            WHEN dm.INVESTIGATOR_INTERVIEW_KEY = tmp.PROVIDER_KEY AND std_hiv_datamart_update >= 1
                    THEN tmp.PROVIDER_QUICK_CODE 
            ELSE dm.INVESTIGATOR_INTERVIEW_QC 
        END,
        INVESTIGATOR_SUPER_CASE_QC = CASE 
            WHEN dm.INVESTIGATOR_SUPER_CASE_KEY = tmp.PROVIDER_KEY AND std_hiv_datamart_update >= 1
                    THEN tmp.PROVIDER_QUICK_CODE
            ELSE dm.INVESTIGATOR_SUPER_CASE_QC
        END,
        INVESTIGATOR_SUPER_FL_FUP_QC = CASE 
            WHEN dm.INVESTIGATOR_SUPER_FL_FUP_KEY = tmp.PROVIDER_KEY AND std_hiv_datamart_update >= 1
                    THEN tmp.PROVIDER_QUICK_CODE 
            ELSE dm.INVESTIGATOR_SUPER_FL_FUP_QC
        END,
        INVESTIGATOR_SURV_QC = CASE 
            WHEN dm.INVESTIGATOR_SURV_KEY = tmp.PROVIDER_KEY AND std_hiv_datamart_update >= 1
                    THEN tmp.PROVIDER_QUICK_CODE 
            ELSE dm.INVESTIGATOR_SURV_QC
        END          
        FROM dbo.STD_HIV_DATAMART dm
        JOIN #PROVIDER_UPDATE_LIST tmp 
        ON std_hiv_datamart_update >= 1
        AND (
            dm.INVESTIGATOR_CLOSED_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_CURRENT_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_DISP_FL_FUP_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_FL_FUP_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_INIT_INTRVW_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_INIT_FL_FUP_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_INITIAL_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_INTERVIEW_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_SUPER_CASE_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_SUPER_FL_FUP_KEY = tmp.PROVIDER_KEY or
            dm.INVESTIGATOR_SURV_KEY = tmp.PROVIDER_KEY
        );
    END

    set @rowcount=@@rowcount;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);


    ---------------------------------------------------------------------------------------------------------------------------------

    SET @proc_step_name=' Update Provider attributes in HEP100_DATAMART for PHYSICIAN';
    SET @proc_step_no = 5.8;


    IF EXISTS (SELECT 1 from dbo.HEP100 dm with (nolock) 
        INNER JOIN #PROVIDER_UPDATE_LIST tmp 
        ON dm.PHYSICIAN_UID = tmp.PROVIDER_UID
            where datamart_update+hep100_datamart_update >= 1
            and dm.PHYSICIAN_UID is not null
    )
    BEGIN
        UPDATE dm
        SET
        PHYSICIAN_NAME = COALESCE(TRIM(tmp.PROVIDER_FIRST_NAME), ' ') + ',' + COALESCE(TRIM(tmp.PROVIDER_MIDDLE_NAME), ' ') + ',' + COALESCE(TRIM(tmp.PROVIDER_LAST_NAME), ' ')
        ,PHYSICIAN_COUNTY = tmp.PROVIDER_COUNTY
        ,PHYSICIAN_CITY = tmp.PROVIDER_CITY
        ,PHYSICIAN_STATE = tmp.PROVIDER_STATE
        ,PHYSICIAN_ADDRESS_USE_DESC = CASE
            WHEN LEN(TRIM(COALESCE(tmp.PROVIDER_CITY, '')) + TRIM(COALESCE(tmp.PROVIDER_STATE, '')) + TRIM(COALESCE(tmp.PROVIDER_COUNTY, ''))) > 0
                THEN 'Primary Work Place'
            ELSE NULL
            END
        ,PHYSICIAN_ADDRESS_TYPE_DESC =  CASE
            WHEN LEN(TRIM(COALESCE(tmp.PROVIDER_CITY, '')) + TRIM(COALESCE(tmp.PROVIDER_STATE, '')) + TRIM(COALESCE(tmp.PROVIDER_COUNTY, ''))) > 0
                THEN 'Office'
            ELSE NULL
            END
        FROM dbo.HEP100 dm
        INNER JOIN #PROVIDER_UPDATE_LIST tmp 
        ON datamart_update+hep100_datamart_update >= 1
            AND dm.PHYSICIAN_UID = tmp.PROVIDER_UID
            where dm.PHYSICIAN_UID is not null
        ;
    END

    set @rowcount=@@rowcount;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);

    SET @proc_step_name=' Update Provider attributes in HEP100_DATAMART for INVESTIGATOR';
    SET @proc_step_no = 5.9;

    IF EXISTS (SELECT 1 from dbo.HEP100 dm with (nolock) 
        INNER JOIN #PROVIDER_UPDATE_LIST tmp 
        ON dm.INVESTIGATOR_UID = tmp.PROVIDER_UID
            where dm.INVESTIGATOR_UID is not null
            and datamart_update+hep100_datamart_update >= 1
    )
    BEGIN
        UPDATE dm
        SET
        INVESTIGATOR_NAME = COALESCE(TRIM(tmp.PROVIDER_FIRST_NAME), ' ') + ',' + COALESCE(TRIM(tmp.PROVIDER_MIDDLE_NAME), ' ') + ',' + COALESCE(TRIM(tmp.PROVIDER_LAST_NAME), ' ')
        FROM dbo.HEP100 dm
        INNER JOIN #PROVIDER_UPDATE_LIST tmp 
        ON datamart_update+hep100_datamart_update >= 1
            AND dm.INVESTIGATOR_UID = tmp.PROVIDER_UID
            where dm.INVESTIGATOR_UID is not null
        ;
    END

    set @rowcount=@@rowcount;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);


    ---------------------------------------------------------------------------------------------------------------------------------
    
    SET @proc_step_name=' Update Provider attributes in TB_DATAMART and TB_HIV_DATAMART for PROVIDER';
    SET @proc_step_no = 5.10;

    select
        h.INVESTIGATION_KEY,
        g.*
    into #INVESTIGATION_PROVIDER_MAPPING_FOR_TB
    from
        dbo.F_TB_PAM d with (nolock)
    inner join dbo.TB_DATAMART h with (nolock)
        on d.INVESTIGATION_KEY = h.INVESTIGATION_KEY
    inner join #PROVIDER_UPDATE_LIST g with (nolock)
        on g.PROVIDER_KEY = d.PROVIDER_KEY
    where tb_datamart_update = 1 ;


    if @debug = 'true'
        select '#INVESTIGATION_PROVIDER_MAPPING_FOR_TB', * from #INVESTIGATION_PROVIDER_MAPPING_FOR_TB;        

    declare @rowcount_tmp bigint =0;

    IF EXISTS (SELECT 1 from #INVESTIGATION_PROVIDER_MAPPING_FOR_TB)
    BEGIN
        update dm
        set 
        INVESTIGATOR_LAST_NAME = map.PROVIDER_LAST_NAME,
        INVESTIGATOR_FIRST_NAME = map.PROVIDER_FIRST_NAME,
        INVESTIGATOR_PHONE_NUMBER = map.PROVIDER_PHONE_WORK
        from dbo.TB_DATAMART dm
        INNER JOIN #INVESTIGATION_PROVIDER_MAPPING_FOR_TB map 
        ON dm.INVESTIGATION_KEY = map.INVESTIGATION_KEY
        ;

        set @rowcount_tmp = @@rowcount;

        update dm
        set
        INVESTIGATOR_LAST_NAME = map.PROVIDER_LAST_NAME,
        INVESTIGATOR_FIRST_NAME = map.PROVIDER_FIRST_NAME,
        INVESTIGATOR_PHONE_NUMBER = map.PROVIDER_PHONE_WORK
        from dbo.TB_HIV_DATAMART dm
        inner join #INVESTIGATION_PROVIDER_MAPPING_FOR_TB map 
        on dm.INVESTIGATION_KEY = map.INVESTIGATION_KEY
        ;

        set @rowcount_tmp = @rowcount_tmp + @@rowcount;
    END
    
    set @rowcount=@rowcount_tmp;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);

    ---------------------------------------------------------------------------------------------------------------------------------

    SET @proc_step_name=' Update Provider attributes in TB_DATAMART and TB_HIV_DATAMART for PHYSICIAN';
    SET @proc_step_no = 5.11;

    select
        h.INVESTIGATION_KEY,
        g.*
    into #INVESTIGATION_PHYSICIAN_MAPPING_FOR_TB
    from
        dbo.F_TB_PAM d with (nolock)
    inner join dbo.TB_DATAMART h with (nolock)
        on d.INVESTIGATION_KEY  = h.INVESTIGATION_KEY
    inner join #PROVIDER_UPDATE_LIST g with (nolock)
        on g.PROVIDER_KEY = d.PHYSICIAN_KEY
    where tb_datamart_update = 1 ;

    if @debug = 'true'
        select '#INVESTIGATION_PHYSICIAN_MAPPING_FOR_TB', * from #INVESTIGATION_PHYSICIAN_MAPPING_FOR_TB;     

    set @rowcount_tmp =0;

    IF EXISTS (SELECT 1 from #INVESTIGATION_PHYSICIAN_MAPPING_FOR_TB)
    BEGIN
        update dm
        set 
        PHYSICIAN_LAST_NAME = map.PROVIDER_LAST_NAME,
        PHYSICIAN_FIRST_NAME = map.PROVIDER_FIRST_NAME,
        PHYSICIAN_PHONE_NUMBER = map.PROVIDER_PHONE_WORK
        from dbo.TB_DATAMART dm
        inner join #INVESTIGATION_PHYSICIAN_MAPPING_FOR_TB map 
        ON dm.INVESTIGATION_KEY = map.INVESTIGATION_KEY
        ;
        set @rowcount_tmp = @@rowcount;

        update dm
        set
        PHYSICIAN_LAST_NAME =  map.PROVIDER_LAST_NAME,
        PHYSICIAN_FIRST_NAME = map.PROVIDER_FIRST_NAME,
        PHYSICIAN_PHONE_NUMBER = map.PROVIDER_PHONE_WORK
        from dbo.TB_HIV_DATAMART dm
        inner join #INVESTIGATION_PHYSICIAN_MAPPING_FOR_TB map 
        on dm.INVESTIGATION_KEY = map.INVESTIGATION_KEY
        ;
        set @rowcount_tmp = @rowcount_tmp + @@rowcount;

    END

    set @rowcount=@rowcount_tmp;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);

    ---------------------------------------------------------------------------------------------------------------------------------
    
    SET @proc_step_name=' Update Provider attributes in TB_DATAMART and TB_HIV_DATAMART for REPORTER';
    SET @proc_step_no = 5.12;

    select
        h.INVESTIGATION_KEY,
        g.*
    into #INVESTIGATION_REPORTER_MAPPING_FOR_TB
    from
        dbo.F_TB_PAM d with (nolock)
    inner join dbo.TB_DATAMART h with (nolock)
        on d.INVESTIGATION_KEY  = h.INVESTIGATION_KEY
    inner join #PROVIDER_UPDATE_LIST g with (nolock)
        on g.PROVIDER_KEY = d.PERSON_AS_REPORTER_KEY
    where tb_datamart_update = 1 ;

    if @debug = 'true'
        select '#INVESTIGATION_REPORTER_MAPPING_FOR_TB', * from #INVESTIGATION_REPORTER_MAPPING_FOR_TB; 

    set @rowcount_tmp =0;

    IF EXISTS (SELECT 1 from #INVESTIGATION_REPORTER_MAPPING_FOR_TB)
    BEGIN
        update dm
        set 
        REPORTER_LAST_NAME = map.PROVIDER_LAST_NAME,
        REPORTER_FIRST_NAME = map.PROVIDER_FIRST_NAME,
        REPORTER_PHONE_NUMBER = map.PROVIDER_PHONE_WORK
        from dbo.TB_DATAMART dm
        inner join #INVESTIGATION_REPORTER_MAPPING_FOR_TB map 
        ON dm.INVESTIGATION_KEY = map.INVESTIGATION_KEY
        ;
        set @rowcount_tmp=@@rowcount;

        update dm 
        set
        REPORTER_LAST_NAME = map.PROVIDER_LAST_NAME,
        REPORTER_FIRST_NAME = map.PROVIDER_FIRST_NAME,
        REPORTER_PHONE_NUMBER = map.PROVIDER_PHONE_WORK
        from dbo.TB_HIV_DATAMART dm
        inner join #INVESTIGATION_REPORTER_MAPPING_FOR_TB map 
        on map.INVESTIGATION_KEY = dm.INVESTIGATION_KEY
        ;
        set @rowcount_tmp=@rowcount_tmp+@@rowcount;

    END

    set @rowcount=@rowcount_tmp;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);


    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    SET @proc_step_name=' Update Provider attributes in AGGREGATE_REPORT_DATAMART';
    SET @proc_step_no = 5.13;

    IF EXISTS (SELECT 1 from dbo.AGGREGATE_REPORT_DATAMART dm with (nolock)
        INNER JOIN #PROVIDER_UPDATE_LIST map
        ON dm.PROVIDER_KEY = map.PROVIDER_KEY and map.PROVIDER_KEY <> 1
            where std_hiv_datamart_update = 1
    )
    BEGIN
        update dm
        set
            PROVIDER_QUICK_CODE = map.PROVIDER_QUICK_CODE
            from dbo.AGGREGATE_REPORT_DATAMART dm
                INNER JOIN #PROVIDER_UPDATE_LIST map
        ON dm.PROVIDER_KEY = map.PROVIDER_KEY and map.PROVIDER_KEY <> 1
        where tb_datamart_update = 1
        ;
    END
    
    set @rowcount=@@rowcount;
    INSERT INTO [dbo].[job_flow_log] 
    (batch_id,[Dataflow_Name],[package_Name],[Status_Type],[step_number],[step_name],[row_count])
    VALUES 
    (@batch_id,@dataflow_name,@package_name,'START',@proc_step_no,@proc_step_name,@rowcount);

END