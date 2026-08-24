package gov.cdc.nbs.report.pipeline.observation.repository;

import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.Observation;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ObservationRepository extends JpaRepository<Observation, String> {

  @Query(
      nativeQuery = true,
      value =
          "execute sp_observation_event @obs_id_list = :observation_uids, "
              + "@debug_logging = :debugLogging")
  Optional<Observation> computeObservations(
      @Param("observation_uids") String observationUids,
      @Param("debugLogging") boolean debugLogging);
}
