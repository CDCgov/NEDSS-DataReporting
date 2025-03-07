package gov.cdc.etldatapipeline.investigation.repository;

import gov.cdc.etldatapipeline.investigation.repository.model.dto.Treatment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface TreatmentRepository extends JpaRepository<Treatment, String> {

    @Query(nativeQuery = true, value = "exec sp_treatment_event :treatment_uid")
    Optional<Treatment> computeTreatment(@Param("treatment_uid") String treatmentUid);
}
