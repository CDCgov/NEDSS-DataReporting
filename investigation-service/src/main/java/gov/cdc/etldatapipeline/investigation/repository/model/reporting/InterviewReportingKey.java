package gov.cdc.etldatapipeline.investigation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.NonNull;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class InterviewReportingKey {
    @NonNull
    @JsonProperty("interview_uid")
    private Long interviewUid;
}
