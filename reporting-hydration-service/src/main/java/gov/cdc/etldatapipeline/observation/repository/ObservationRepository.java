package gov.cdc.etldatapipeline.observation.repository;

import gov.cdc.etldatapipeline.observation.model.dto.observation.Observation;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ObservationRepository extends JpaRepository<Observation, String> {

  @Query(nativeQuery = true, value = "execute sp_Observation_Event :observation_uids")
  Optional<Observation> computeObservations(@Param("observation_uids") String observation_uids);
}
