package gov.cdc.etldatapipeline.postprocessingservice.repository;

import gov.cdc.etldatapipeline.postprocessingservice.repository.model.BackfillData;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.DatamartData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PostProcRepository extends JpaRepository<DatamartData, Long> {
    @Query(value = "EXEC sp_nrt_organization_postprocessing :organizationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForOrganizationIds(@Param("organizationUids") String organizationUids);

    @Query(value = "EXEC sp_nrt_provider_postprocessing :providerUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForProviderIds(@Param("providerUids") String providerUids);

    @Query(value = "EXEC sp_nrt_patient_postprocessing :patientUids", nativeQuery = true)
    List<DatamartData>  executeStoredProcForPatientIds(@Param("patientUids") String patientUids);

    @Query(value = "EXEC sp_nrt_ldf_postprocessing :ldfUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLdfIds(@Param("ldfUids") String ldfUids);

    @Query(value = "EXEC sp_d_morbidity_report_postprocessing :observationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForMorbReport(@Param("observationUids") String observationUids);

    @Query(value = "EXEC sp_d_lab_test_postprocessing :observationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLabTest(@Param("observationUids") String observationUids);

    @Query(value = "EXEC sp_d_labtest_result_postprocessing :observationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLabTestResult(@Param("observationUids") String observationUids);

    @Query(value = "EXEC sp_lab100_datamart_postprocessing :observationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLab100Datamart(@Param("observationUids") String observationUids);

    @Query(value = "EXEC sp_lab101_datamart_postprocessing :observationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLab101Datamart(@Param("observationUids") String observationUids);

    @Query(value = "EXEC sp_d_interview_postprocessing :interviewUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDInterview(@Param("interviewUids") String interviewUids);

    @Query(value = "EXEC sp_f_interview_case_postprocessing :interviewUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForFInterviewCase(@Param("interviewUids") String interviewUids);

    @Query(value = "EXEC sp_nrt_place_postprocessing :placeUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDPlace(@Param("placeUids") String placeUids);

    @Query(value = "EXEC sp_user_profile_postprocessing :userProfileUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForUserProfile(@Param("userProfileUids") String userProfileUids);

    @Query(value = "EXEC sp_d_contact_record_postprocessing :contactUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDContactRecord(@Param("contactUids") String contactUids);

    @Procedure("sp_event_metric_datamart_postprocessing")
    void executeStoredProcForEventMetric(
            @Param("publicHealthCaseUids") String publicHealthCaseUids,
            @Param("observationUids") String observationUids,
            @Param("notificationUids") String notificationUids,
            @Param("contactRecordUids") String contactRecordUids,
            @Param("vaccinationUids") String vaccinationUids);

    @Query(value = "EXEC sp_f_contact_record_case_postprocessing :contactUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForFContactRecordCase(@Param("contactUids") String contactUids);

    @Query(value = "exec sp_nrt_treatment_postprocessing :treatmentUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForTreatment(@Param("treatmentUids") String treatmentUids);

    @Query(value = "exec sp_d_vaccination_postprocessing :vaccinationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDVaccination(@Param("vaccinationUids") String vaccinationUids);

    @Query(value = "exec sp_inv_summary_datamart_postprocessing :publicHealthCaseUids, :notificationUids, :observationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForInvSummaryDatamart(
            @Param("publicHealthCaseUids") String publicHealthCaseUids,
            @Param("notificationUids") String notificationUids,
            @Param("observationUids") String observationUids
    );

    @Query(value = "exec sp_f_vaccination_postprocessing :vaccinationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForFVaccination(@Param("vaccinationUids") String vaccinationUids);

    @Procedure("sp_morbidity_report_datamart_postprocessing")
    void executeStoredProcForMorbidityReportDatamart(
            @Param("observationUids") String observationUids,
            @Param("patientUids") String patientUids,
            @Param("providerUids") String providerUids,
            @Param("organizationUids") String organizationUids,
            @Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_dyn_dm_main_postprocessing")
    void executeStoredProcForDynDatamart(
            @Param("datamart") String datamart,
            @Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "exec sp_nrt_ldf_dimensional_data_postprocessing :ldfUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLdfDimensionalData(@Param("ldfUids") String ldfUids);

    @Query(value = "exec sp_nrt_odse_nbs_page_postprocessing :pageUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForNBSPage(@Param("pageUids") String pageUids);

    @Procedure("sp_nrt_srte_condition_code_postprocessing")
    void executeStoredProcForConditionCode(@Param("conditionCds") String conditionCds);

    @Procedure("sp_nrt_backfill_postprocessing")
    void executeStoredProcForBackfill(
            @Param("entity")  String entity,
            @Param("backfillUids") String backfillUids,
            @Param("batchId") Long batchId,
            @Param("errDesc") String errDesc,
            @Param("statusCd") String statusCd,
            @Param("retryCnt") Integer retryCnt);

    @Query(value = "EXEC sp_nrt_backfill_event :statusCd", nativeQuery = true)
    List<BackfillData> executeBackfillEvent(@Param("statusCd") String statusCd);
}