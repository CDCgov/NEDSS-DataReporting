package gov.cdc.nbs.report.pipeline.investigation.repository;

import gov.cdc.nbs.report.pipeline.investigation.repository.model.dto.Vaccination;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface VaccinationRepository extends JpaRepository<Vaccination, String> {

  @Query(
      nativeQuery = true,
      value =
          "execute sp_vaccination_event @vac_uids = :vaccination_uid, "
              + "@debug = 0, @debug_logging = :debugLogging")
  Optional<Vaccination> computeVaccination(
      @Param("vaccination_uid") String vaccinationUid, @Param("debugLogging") boolean debugLogging);
}
