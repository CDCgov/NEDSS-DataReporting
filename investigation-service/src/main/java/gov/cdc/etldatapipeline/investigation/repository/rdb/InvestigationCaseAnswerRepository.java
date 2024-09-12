package gov.cdc.etldatapipeline.investigation.repository.rdb;

import gov.cdc.etldatapipeline.investigation.repository.model.dto.InvestigationCaseAnswer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface InvestigationCaseAnswerRepository extends JpaRepository<InvestigationCaseAnswer, Long> {
    void deleteByActUid(Long actUid);
}
