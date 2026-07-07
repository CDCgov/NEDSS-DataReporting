package gov.cdc.nbs.report.pipeline.person.repository;

import gov.cdc.nbs.report.pipeline.person.model.entity.NrtProvider;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface NrtProviderRepository extends JpaRepository<NrtProvider, Long> {}
