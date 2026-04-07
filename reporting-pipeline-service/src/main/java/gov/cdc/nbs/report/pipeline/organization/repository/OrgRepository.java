package gov.cdc.nbs.report.pipeline.organization.repository;

import gov.cdc.nbs.report.pipeline.organization.model.dto.org.OrganizationSp;
import java.util.Set;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface OrgRepository extends JpaRepository<OrganizationSp, String> {

  @Query(nativeQuery = true, value = "execute sp_organization_event :org_uids")
  Set<OrganizationSp> computeAllOrganizations(@Param("org_uids") String orgUids);

  @Procedure("sp_public_health_case_fact_datamart_update")
  void updatePhcFact(@Param("objName") String objName, @Param("uidLst") String uidLst);
}
