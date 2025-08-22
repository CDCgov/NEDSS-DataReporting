package gov.cdc.etldatapipeline.postprocessingservice.repository.rdbmodern;

import gov.cdc.etldatapipeline.postprocessingservice.repository.rdbmodern.model.DeadLetterLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface DeadLetterLogRepository extends JpaRepository<DeadLetterLog, String> {
}
