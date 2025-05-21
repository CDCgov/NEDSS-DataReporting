package gov.cdc.etldatapipeline.postprocessingservice.repository;

import gov.cdc.etldatapipeline.postprocessingservice.repository.model.DatamartData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PostProcRepository extends JpaRepository<DatamartData, Long> {
    @Procedure("sp_nrt_organization_postprocessing")
    void executeStoredProcForOrganizationIds(@Param("organizationUids") String organizationUids);

    @Procedure("sp_nrt_provider_postprocessing")
    void executeStoredProcForProviderIds(@Param("providerUids") String providerUids);

    @Query(value = "EXEC sp_nrt_patient_postprocessing :patientUids", nativeQuery = true)
    List<DatamartData>  executeStoredProcForPatientIds(@Param("patientUids") String patientUids);

    @Procedure("sp_nrt_ldf_postprocessing")
    void executeStoredProcForLdfIds(@Param("ldfUids") String ldfUids);

    @Query(value = "EXEC sp_d_morbidity_report_postprocessing :observationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForMorbReport(@Param("observationUids") String observationUids);

    @Procedure("sp_d_lab_test_postprocessing")
    void executeStoredProcForLabTest(@Param("observationUids") String observationUids);

    @Query(value = "EXEC sp_d_labtest_result_postprocessing :observationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLabTestResult(@Param("observationUids") String observationUids);

    @Procedure("sp_lab100_datamart_postprocessing")
    void executeStoredProcForLab100Datamart(@Param("observationUids") String observationUids);

    @Procedure("sp_lab101_datamart_postprocessing")
    void executeStoredProcForLab101Datamart(@Param("observationUids") String observationUids);

    @Procedure("sp_d_interview_postprocessing")
    void executeStoredProcForDInterview(@Param("interviewUids") String interviewUids);

    @Procedure("sp_f_interview_case_postprocessing")
    void executeStoredProcForFInterviewCase(@Param("interviewUids") String interviewUids);

    @Procedure("sp_nrt_place_postprocessing")
    void executeStoredProcForDPlace(@Param("placeUids") String placeUids);

    @Procedure("sp_user_profile_postprocessing")
    void executeStoredProcForUserProfile(@Param("userProfileUids") String userProfileUids);

    @Query(value = "EXEC sp_d_contact_record_postprocessing :contactUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDContactRecord(@Param("contactUids") String contactUids);

    @Procedure("sp_event_metric_datamart_postprocessing")
    void executeStoredProcForEventMetric(
            @Param("publicHealthCaseUids") String publicHealthCaseUids,
            @Param("observationUids") String observationUids,
            @Param("notificationUids") String notificationUids,
            @Param("contactRecordUids") String contactRecordUids,
            @Param("vaccinationUids") String vaccinationUids);
            
    @Procedure("sp_f_contact_record_case_postprocessing")
    void executeStoredProcForFContactRecordCase(@Param("contactUids") String contactUids);

    @Procedure("sp_hep100_datamart_postprocessing")
    void executeStoredProcForHep100(
            @Param("publicHealthCaseUids") String publicHealthCaseUids,
            @Param("patientUids") String patientUids,
            @Param("providerUids") String providerUids,
            @Param("organizationUids") String organizationUids);

    @Procedure("sp_nrt_treatment_postprocessing")
    void executeStoredProcForTreatment(@Param("treatmentUids") String treatmentUids);

    @Query(value = "exec sp_d_vaccination_postprocessing :vaccinationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDVaccination(@Param("vaccinationUids") String vaccinationUids);

    @Query(value = "exec sp_inv_summary_datamart_postprocessing :publicHealthCaseUids, :notificationUids, :observationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForInvSummaryDatamart(
            @Param("publicHealthCaseUids") String publicHealthCaseUids,
            @Param("notificationUids") String notificationUids,
            @Param("observationUids") String observationUids
    );

    @Procedure("sp_f_vaccination_postprocessing")
    void executeStoredProcForFVaccination(@Param("vaccinationUids") String vaccinationUids);

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

   @Procedure("sp_nrt_ldf_dimensional_data_postprocessing")
    void executeStoredProcForLdfDimensionalData(@Param("ldfUids") String ldfUids);

    @Procedure("sp_nrt_odse_nbs_page_postprocessing")
    void executeStoredProcForNBSPage(@Param("pageUids") String pageUids);
     
}
   
