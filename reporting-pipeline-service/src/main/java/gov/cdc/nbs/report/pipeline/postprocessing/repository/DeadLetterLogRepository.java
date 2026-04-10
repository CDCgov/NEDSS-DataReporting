package gov.cdc.nbs.report.pipeline.postprocessing.repository;

import gov.cdc.nbs.report.pipeline.postprocessing.repository.model.DeadLetterLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DeadLetterLogRepository extends JpaRepository<DeadLetterLog, String> {}
