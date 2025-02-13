package gov.cdc.etldatapipeline.postprocessingservice.service;

import lombok.Getter;

@Getter
enum Entity {
    ORGANIZATION(1, "organization", "organization_uid", "sp_nrt_organization_postprocessing"),
    PROVIDER(2, "provider", "provider_uid", "sp_nrt_provider_postprocessing"),
    PATIENT(3, "patient", "patient_uid", "sp_nrt_patient_postprocessing"),
    USER_PROFILE(4, "user_profile", "userProfileUids", "sp_user_profile_postprocessing"),
    D_PLACE(5, "place", "place_uid", "sp_nrt_place_postprocessing"),
    INVESTIGATION(6, "investigation", Constants.PHC_UID, "sp_nrt_investigation_postprocessing"),
    NOTIFICATION(7, "notification", "notification_uid", "sp_nrt_notification_postprocessing"),
    INTERVIEW(8, "interview", "interview_uid", "sp_d_interview_postprocessing"),
    CASE_MANAGEMENT(9, "case_management", Constants.PHC_UID, "sp_nrt_case_management_postprocessing"),
    LDF_DATA(10, "ldf_data", "ldf_uid", "sp_nrt_ldf_postprocessing"),
    OBSERVATION(11, "observation", "observation_uid", null),
    CONTACT(12, "contact", "contact_uid", "sp_d_contact_record_postprocessing"),
    F_PAGE_CASE(0, "fact page case", Constants.PHC_UID, "sp_f_page_case_postprocessing"),
    CASE_ANSWERS(0, "case answers", Constants.PHC_UID, "sp_page_builder_postprocessing"),
    CASE_COUNT(0, "case count", Constants.PHC_UID, "sp_nrt_case_count_postprocessing"),
    F_STD_PAGE_CASE(0, "fact std page case", Constants.PHC_UID, "sp_f_std_page_case_postprocessing"),
    HEPATITIS_DATAMART(0, "Hepatitis_Datamart", Constants.PHC_UID, "sp_hepatitis_datamart_postprocessing"),
    STD_HIV_DATAMART(0, "Std_Hiv_Datamart", Constants.PHC_UID, "sp_std_hiv_datamart_postprocessing"),
    GENERIC_CASE(0, "Generic_Case", Constants.PHC_UID, "sp_generic_case_datamart_postprocessing"),
    CRS_CASE(0, "CRS_Case", Constants.PHC_UID, "sp_crs_case_datamart_postprocessing"),
    RUBELLA_CASE(0, "Rubella_Case", Constants.PHC_UID, "sp_rubella_case_datamart_postprocessing"),
    MEASLES_CASE(0, "Measles_Case", Constants.PHC_UID, "sp_measles_case_datamart_postprocessing"),
    CASE_LAB_DATAMART(0, "Case_Lab_Datamart", Constants.PHC_UID, "sp_case_lab_datamart_postprocessing"),
    BMIRD_CASE_DATAMART(0, "Bmird_Case_Datamart", Constants.PHC_UID, "sp_bmird_case_datamart_postprocessing"),
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
