package gov.cdc.etldatapipeline.investigation.repository;

import gov.cdc.etldatapipeline.investigation.repository.model.dto.Vaccination;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface VaccinationRepository extends JpaRepository<Vaccination, String> {

    @Query(nativeQuery = true, value = "exec sp_vaccination_event :vaccination_uid")
    Optional<Vaccination> computeVaccination(@Param("vaccination_uid") String vaccinationUid);
}
