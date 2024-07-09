package gov.cdc.etldatapipeline.postprocessingservice.repository;

import gov.cdc.etldatapipeline.postprocessingservice.repository.model.InvestigationResult;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface InvestigationRepository extends JpaRepository<InvestigationResult, Long> {
    @Query(value = "EXEC sp_nrt_investigation_postprocessing :publicHealthCaseUids", nativeQuery = true)
    List<InvestigationResult> executeStoredProcForPublicHealthCaseIds(@Param("publicHealthCaseUids") String publicHealthCaseUids);

    @Procedure("sp_f_page_case_postprocessing")
    void executeStoredProcForFPageCase(@Param("publicHealthCaseUids") String publicHealthCaseUids);
}
