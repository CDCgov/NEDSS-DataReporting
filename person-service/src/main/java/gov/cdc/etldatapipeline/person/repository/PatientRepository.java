package gov.cdc.etldatapipeline.person.repository;

import gov.cdc.etldatapipeline.person.model.dto.patient.PatientSp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PatientRepository extends JpaRepository<PatientSp, String> {
    @Query(nativeQuery = true, value = "execute sp_Patient_Event :person_uids")
    List<PatientSp> computePatients(@Param("person_uids") String personUids);

    @Procedure("sp_public_health_case_fact_datamart_update")
    void updatePhcFact(@Param("objName") String objName, @Param("uidLst") String uidLst);
}
