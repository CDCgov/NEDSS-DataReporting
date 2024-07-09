package gov.cdc.etldatapipeline.postprocessingservice.repository;

import gov.cdc.etldatapipeline.postprocessingservice.repository.model.PageBuilderStoredProc;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;

public interface PageBuilderRepository extends JpaRepository<PageBuilderStoredProc, Long> {
    @Procedure("sp_page_builder_postprocessing")
    void executeStoredProcForPageBuilder(@Param("phcUid") Long phcUid, @Param("rdbTableNmLst") String rdbTableNmLst);
}
