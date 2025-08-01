package gov.cdc.etldatapipeline.postprocessingservice.repository;

import gov.cdc.etldatapipeline.postprocessingservice.repository.model.DatamartData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface InvestigationRepository extends JpaRepository<DatamartData, Long> {
    @Query(value = "EXEC sp_nrt_investigation_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForPublicHealthCaseIds(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_notification_postprocessing :notificationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForNotificationIds(@Param("notificationUids") String notificationUids);

    @Query(value = "EXEC sp_page_builder_postprocessing :phcUids, :rdbTableNm", nativeQuery = true)
    List<DatamartData> executeStoredProcForPageBuilder(@Param("phcUids") String phcUids, @Param("rdbTableNm") String rdbTableNm);

    @Query(value = "EXEC sp_f_page_case_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForFPageCase(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_case_count_postprocessing :healthcaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForCaseCount(@Param("healthcaseUids") String healthcaseUids);

    @Query(value = "EXEC sp_nrt_case_management_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForCaseManagement(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_f_std_page_case_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForFStdPageCase(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_hepatitis_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForHepDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_std_hiv_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForStdHIVDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_generic_case_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForGenericCaseDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_crs_case_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForCRSCaseDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_rubella_case_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForRubellaCaseDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_measles_case_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForMeaslesCaseDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_case_lab_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForCaseLabDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_bmird_case_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForBmirdCaseDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_hepatitis_case_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForHepatitisCaseDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_pertussis_case_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForPertussisCaseDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_bmird_strep_pneumo_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForBmirdStrepPneumoDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_summary_report_case_postprocessing")
    void executeStoredProcForSummaryReportCase(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_sr100_datamart_postprocessing")
    void executeStoredProcForSR100Datamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_aggregate_report_datamart_postprocessing")
    void executeStoredProcForAggregateReport(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_tb_pam_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDTbPam(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_disease_site_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDDiseaseSite(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_addl_risk_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDAddlRisk(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_tb_hiv_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDTbHiv(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_move_cntry_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDMoveCntry(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_move_cnty_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDMoveCnty(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_move_state_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDMoveState(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_out_of_cntry_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDOutOfCntry(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_moved_where_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDMovedWhere(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_gt_12_reas_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDGt12Reas(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_hc_prov_ty_3_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDHcProvTy3(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_smr_exam_ty_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDSmrExamTy(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_f_tb_pam_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForFTbPam(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_tb_pam_ldf_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForTbPamLdf(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_var_pam_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDVarPam(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_rash_loc_gen_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDRashLocGen(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_d_pcr_source_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForDPcrSource(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_nrt_var_pam_ldf_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForVarPamLdf(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_f_var_pam_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForFVarPam(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_tb_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForTbDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);
    
    @Query(value = "EXEC sp_tb_hiv_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForTbHivDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);
    
    @Query(value = "EXEC sp_var_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForVarDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_ldf_generic_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLdfGenericDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_ldf_bmird_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLdfBmirdDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);
    
    @Query(value = "EXEC sp_ldf_foodborne_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLdfFoodBorneDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_ldf_mumps_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLdfMumpsDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_ldf_tetanus_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLdfTetanusDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_ldf_vaccine_prevent_diseases_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLdfVacPreventDiseasesDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_ldf_hepatitis_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForLdfHepatitisDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_covid_case_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForCovidCaseDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_covid_contact_datamart_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForCovidContactDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Query(value = "EXEC sp_covid_vaccination_datamart_postprocessing :vacUids, :patientUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForCovidVacDatamart(@Param("vacUids") String vacUids, @Param("patientUids") String patientUids);

    @Query(value = "EXEC sp_covid_lab_datamart_postprocessing :observationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForCovidLabDatamart(@Param("observationUids") String observationUids);

    @Query(value = "EXEC sp_covid_lab_celr_datamart_postprocessing :observationUids", nativeQuery = true)
    List<DatamartData> executeStoredProcForCovidLabCelrDatamart(@Param("observationUids") String observationUids);
}
