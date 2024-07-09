package gov.cdc.etldatapipeline.postprocessingservice.repository;

import gov.cdc.etldatapipeline.postprocessingservice.repository.model.OrganizationStoredProc;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface OrganizationRepository extends JpaRepository<OrganizationStoredProc, Long> {
    @Procedure("sp_nrt_organization_postprocessing")
    void executeStoredProcForOrganizationIds(@Param("organizationUids") String organizationUids);
}
