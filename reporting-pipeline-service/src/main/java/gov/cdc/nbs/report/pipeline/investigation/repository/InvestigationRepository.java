package gov.cdc.nbs.report.pipeline.investigation.repository;

import gov.cdc.nbs.report.pipeline.investigation.repository.model.dto.Investigation;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface InvestigationRepository extends JpaRepository<Investigation, String> {

  @Query(
      nativeQuery = true,
      value =
          "execute sp_investigation_event @phc_id_list = :investigation_uids, "
              + "@debug_logging = :debugLogging")
  Optional<Investigation> computeInvestigations(
      @Param("investigation_uids") String investigationUids,
      @Param("debugLogging") boolean debugLogging);

  @Query(
      nativeQuery = true,
      value =
          "execute sp_public_health_case_fact_datamart_event "
              + "@phc_id_list = :phcIds, @debug = 0, @debug_logging = :debugLogging")
  void populatePhcFact(@Param("phcIds") String phcIds, @Param("debugLogging") boolean debugLogging);

  @Procedure("sp_public_health_case_fact_datamart_update")
  void updatePhcFact(@Param("objName") String objName, @Param("uidLst") String uidLst);
}
