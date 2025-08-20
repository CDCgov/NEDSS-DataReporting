package gov.cdc.etldatapipeline.organization.repository;

import gov.cdc.etldatapipeline.organization.model.dto.org.OrganizationSp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Set;

@Repository
public interface OrgRepository extends JpaRepository<OrganizationSp, String> {

    @Query(nativeQuery = true, value = "execute sp_organization_event :org_uids")
    Set<OrganizationSp> computeAllOrganizations(@Param("org_uids") String orgUids);

    @Query(nativeQuery = true, value = "exec sp_public_health_case_fact_datamart_update :objName, :uidLst")
    void updatePhcFact(@Param("objName") String objName, @Param("uidLst") String uidLst);
}
