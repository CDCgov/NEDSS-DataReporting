package gov.cdc.nbs.report.pipeline.person.repository;

import gov.cdc.nbs.report.pipeline.person.model.entity.NrtAuthUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface NrtAuthUserRepository extends JpaRepository<NrtAuthUser, Long> {}
