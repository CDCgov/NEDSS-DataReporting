package gov.cdc.nbs.report.pipeline.investigation.repository;

import gov.cdc.nbs.report.pipeline.investigation.repository.model.dto.Treatment;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface TreatmentRepository extends JpaRepository<Treatment, String> {

  @Query(
      nativeQuery = true,
      value =
          "execute sp_treatment_event @treatment_uids = :treatment_uid, "
              + "@debug = 0, @debug_logging = :debugLogging")
  Optional<Treatment> computeTreatment(
      @Param("treatment_uid") String treatmentUid, @Param("debugLogging") boolean debugLogging);
}
