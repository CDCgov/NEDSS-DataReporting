package gov.cdc.nbs.report.pipeline.investigation.repository;

import gov.cdc.nbs.report.pipeline.investigation.repository.model.dto.Interview;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface InterviewRepository extends JpaRepository<Interview, String> {

  @Query(nativeQuery = true, value = "exec sp_interview_event :interview_uids")
  Optional<Interview> computeInterviews(@Param("interview_uids") String interviewUids);
}
