package gov.cdc.etldatapipeline.postprocessingservice.repository;

import gov.cdc.etldatapipeline.postprocessingservice.repository.model.PatientStoredProc;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface PatientRepository extends JpaRepository<PatientStoredProc, Long> {
    @Procedure("sp_nrt_patient_postprocessing")
    void executeStoredProcForPatientIds(@Param("patientUids") String patientUids);
}
