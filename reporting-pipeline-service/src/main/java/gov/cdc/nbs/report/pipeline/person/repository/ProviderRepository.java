package gov.cdc.nbs.report.pipeline.person.repository;

import gov.cdc.nbs.report.pipeline.person.model.dto.provider.ProviderSp;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ProviderRepository extends JpaRepository<ProviderSp, String> {
  @Query(nativeQuery = true, value = "execute sp_provider_event :person_uids")
  List<ProviderSp> computeProviders(@Param("person_uids") String personUids);
}
