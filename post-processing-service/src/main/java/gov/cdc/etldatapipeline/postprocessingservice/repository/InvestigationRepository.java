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

    @Procedure("sp_page_builder_postprocessing")
    void executeStoredProcForPageBuilder(@Param("phcUid") Long phcUid, @Param("rdbTableNmLst") String rdbTableNmLst);

    @Procedure("sp_f_page_case_postprocessing")
    void executeStoredProcForFPageCase(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_hepatitis_datamart_postprocessing")
    void executeStoredProcForHepDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_nrt_case_count_postprocessing")
    void executeStoredProcForCaseCount(@Param("healthcaseUids") String healthcaseUids);

    @Procedure("sp_nrt_case_management_postprocessing")
    void executeStoredProcForCaseManagement(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_f_std_page_case_postprocessing")
    void executeStoredProcForFStdPageCase(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_std_hiv_datamart_postprocessing")
    void executeStoredProcForStdHIVDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_generic_case_datamart_postprocessing")
    void executeStoredProcForGenericCaseDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_crs_case_datamart_postprocessing")
    void executeStoredProcForCRSCaseDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_rubella_case_datamart_postprocessing")
    void executeStoredProcForRubellaCaseDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_measles_case_datamart_postprocessing")
    void executeStoredProcForMeaslesCaseDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_case_lab_datamart_postprocessing")
    void executeStoredProcForCaseLabDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_bmird_case_datamart_postprocessing")
    void executeStoredProcForBmirdCaseDatamart(@Param("publicHealthCaseUids") String publicHealthCaseUids);
}
