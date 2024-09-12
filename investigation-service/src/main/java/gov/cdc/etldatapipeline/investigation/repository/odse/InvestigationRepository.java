package gov.cdc.etldatapipeline.investigation.repository.odse;

import gov.cdc.etldatapipeline.investigation.repository.model.dto.Investigation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface InvestigationRepository extends JpaRepository<Investigation, String> {

    @Query(nativeQuery = true, value = "execute sp_investigation_event :investigation_uids")
    Optional<Investigation> computeInvestigations(@Param("investigation_uids") String investigationUids);

    @Query(nativeQuery = true, value = "exec sp_public_health_case_fact_datamart_event :investigation_uids")
    void populatePhcFact(@Param("investigation_uids") String phcIds);
}