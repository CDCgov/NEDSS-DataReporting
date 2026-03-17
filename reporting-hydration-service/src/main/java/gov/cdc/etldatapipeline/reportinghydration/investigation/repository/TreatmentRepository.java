package gov.cdc.etldatapipeline.reportinghydration.investigation.repository;

import gov.cdc.etldatapipeline.reportinghydration.investigation.repository.model.dto.Treatment;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface TreatmentRepository extends JpaRepository<Treatment, String> {

  @Query(nativeQuery = true, value = "exec sp_treatment_event :treatment_uid")
  Optional<Treatment> computeTreatment(@Param("treatment_uid") String treatmentUid);
}
