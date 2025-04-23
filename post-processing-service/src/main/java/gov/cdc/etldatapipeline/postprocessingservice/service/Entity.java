package gov.cdc.etldatapipeline.postprocessingservice.service;

import lombok.Getter;

@Getter
enum Entity {
    ORGANIZATION(1, "organization", "organization_uid", "sp_nrt_organization_postprocessing"),
    PROVIDER(2, "provider", "provider_uid", "sp_nrt_provider_postprocessing"),
    PATIENT(3, "patient", "patient_uid", "sp_nrt_patient_postprocessing"),
    AUTH_USER(4, "auth_user", "auth_user_uid", "sp_user_profile_postprocessing"),
    D_PLACE(5, "place", "place_uid", "sp_nrt_place_postprocessing"),
    INVESTIGATION(6, "investigation", Constants.PHC_UID, "sp_nrt_investigation_postprocessing"),
    NOTIFICATION(7, "notification", "notification_uid", "sp_nrt_notification_postprocessing"),
    TREATMENT(8, "treatment", "treatment_uid", "sp_nrt_treatment_postprocessing"),
    INTERVIEW(9, "interview", "interview_uid", "sp_d_interview_postprocessing"),
    CASE_MANAGEMENT(10, "case_management", Constants.PHC_UID, "sp_nrt_case_management_postprocessing"),
    LDF_DATA(11, "ldf_data", "ldf_uid", "sp_nrt_ldf_postprocessing"),
    OBSERVATION(12, "observation", "observation_uid", null),
    CONTACT(13, "contact", "contact_uid", "sp_d_contact_record_postprocessing"),
    VACCINATION(14, "vaccination", "vaccination_uid", "sp_d_vaccination_postprocessing"),
    F_PAGE_CASE(0, "fact page case", Constants.PHC_UID, "sp_f_page_case_postprocessing"),
    CASE_ANSWERS(0, "case answers", Constants.PHC_UID, "sp_page_builder_postprocessing"),
    D_DISEASE_SITE(0, "disease site", Constants.PHC_UID, "sp_nrt_d_disease_site_postprocessing"),
    D_ADDL_RISK(0, "addl risk", Constants.PHC_UID, "sp_nrt_d_addl_risk_postprocessing"),
    D_MOVE_CNTRY(0, "move cntry", Constants.PHC_UID, "sp_nrt_d_move_cntry_postprocessing"),
    D_MOVE_CNTY(0, "move cnty", Constants.PHC_UID, "sp_nrt_d_move_cnty_postprocessing"),
    D_MOVE_STATE(0, "move state", Constants.PHC_UID, "sp_nrt_d_move_state_postprocessing"),
    D_MOVED_WHERE(0, "moved where", Constants.PHC_UID, "sp_nrt_d_moved_where_postprocessing"),
    CASE_COUNT(0, "case count", Constants.PHC_UID, "sp_nrt_case_count_postprocessing"),
    D_TB_PAM(0, "d_tb_pam", Constants.PHC_UID, "sp_nrt_d_tb_pam_postprocessing"),
    D_VAR_PAM(0, "var pam", Constants.PHC_UID, "sp_nrt_d_var_pam_postprocessing"),
    D_RASH_LOC_GEN(0, "rash loc gen", Constants.PHC_UID, "sp_nrt_d_rash_loc_gen_postprocessing"),
    SUMMARY_REPORT_CASE(0, "Summary_Report_Case", Constants.PHC_UID, "sp_summary_report_case_postprocessing"),
    SR100_DATAMART(0, "SR100_Datamart", Constants.PHC_UID, "sp_sr100_datamart_postprocessing"),
    AGGREGATE_REPORT_DATAMART(0, "Aggregate_Report_Datamart", Constants.PHC_UID, "sp_aggregate_report_datamart_postprocessing"),
    F_STD_PAGE_CASE(0, "fact std page case", Constants.PHC_UID, "sp_f_std_page_case_postprocessing"),
    HEPATITIS_DATAMART(0, "Hepatitis_Datamart", Constants.PHC_UID, "sp_hepatitis_datamart_postprocessing"),
    STD_HIV_DATAMART(0, "Std_Hiv_Datamart", Constants.PHC_UID, "sp_std_hiv_datamart_postprocessing"),
    GENERIC_CASE(0, "Generic_Case", Constants.PHC_UID, "sp_generic_case_datamart_postprocessing"),
    CRS_CASE(0, "CRS_Case", Constants.PHC_UID, "sp_crs_case_datamart_postprocessing"),
    RUBELLA_CASE(0, "Rubella_Case", Constants.PHC_UID, "sp_rubella_case_datamart_postprocessing"),
    MEASLES_CASE(0, "Measles_Case", Constants.PHC_UID, "sp_measles_case_datamart_postprocessing"),
    CASE_LAB_DATAMART(0, "Case_Lab_Datamart", Constants.PHC_UID, "sp_case_lab_datamart_postprocessing"),
    BMIRD_CASE(0, "BMIRD_Case", Constants.PHC_UID, "sp_bmird_case_datamart_postprocessing"),
    HEPATITIS_CASE(0, "Hepatitis_Case", Constants.PHC_UID, "sp_hepatitis_case_datamart_postprocessing"),
    PERTUSSIS_CASE(0, "Pertussis_Case", Constants.PHC_UID, "sp_pertussis_case_datamart_postprocessing"),
    BMIRD_STREP_PNEUMO_DATAMART(0, "Bmird_Strep_Pneumo_Datamart", Constants.PHC_UID, "sp_bmird_strep_pneumo_datamart_postprocessing"),
    D_TB_HIV(0, "d_tb_hiv", Constants.PHC_UID, "sp_nrt_d_tb_hiv_postprocessing"),
    D_GT_12_REAS(0, "d_gt_12_reas", Constants.PHC_UID, "sp_nrt_d_gt_12_reas_postprocessing"),
    D_HC_PROV_TY_3(0, "d_hc_prov_ty_3", Constants.PHC_UID, "sp_d_hc_prov_ty_3_postprocessing"),
    D_OUT_OF_CNTRY(0, "d_out_of_cntry", Constants.PHC_UID, "sp_nrt_d_out_of_cntry_postprocessing"),
    D_SMR_EXAM_TY(0, "d_smr_exam_ty", Constants.PHC_UID, "sp_nrt_d_smr_exam_ty_postprocessing"),
    F_TB_PAM(0, "f_tb_pam", Constants.PHC_UID, "sp_f_tb_pam_postprocessing"),    
    TB_PAM_LDF(0, "tb_pam_ldf", Constants.PHC_UID, "sp_nrt_tb_pam_ldf_postprocessing"),
    VAR_PAM_LDF(0, "var_pam_ldf", Constants.PHC_UID, "sp_nrt_var_pam_ldf_postprocessing"),
    D_PCR_SOURCE(0, "d_pcr_source", Constants.PHC_UID, "sp_nrt_d_pcr_source_postprocessing"),
    F_VAR_PAM(0, "f_var_pam", Constants.PHC_UID, "sp_f_var_pam_postprocessing"),
    TB_DATAMART(0, "tb_datamart", Constants.PHC_UID, "sp_tb_datamart_postprocessing"),    
    TB_HIV_DATAMART(0, "tb_hiv_datamart", Constants.PHC_UID, "sp_tb_hiv_datamart_postprocessing"),
    VAR_DATAMART(0, "var_datamart", Constants.PHC_UID, "sp_var_datamart_postprocessing"),
    LDF_DIMENSIONAL_DATA(0, "ldf_dimensional_data", Constants.PHC_UID, "sp_nrt_ldf_dimensional_data_postprocessing"),
    LDF_GENERIC(0, "LDF_GENERIC", Constants.PHC_UID, "sp_ldf_generic_datamart_postprocessing"),
    LDF_BMIRD(0, "LDF_BMIRD", Constants.PHC_UID, "sp_ldf_bmird_datamart_postprocessing"),
    UNKNOWN(-1, "unknown", "unknown_uid", "sp_nrt_unknown_postprocessing"); 

    private final int priority;
    private final String entityName;
    private final String storedProcedure;
    private final String uidName;

    Entity(int priority, String entityName, String uidName, String storedProcedure) {
        this.priority = priority;
        this.entityName = entityName;
        this.storedProcedure = storedProcedure;
        this.uidName = uidName;
    }

    private static class Constants {
        static final String PHC_UID = "public_health_case_uid";
    }
}
