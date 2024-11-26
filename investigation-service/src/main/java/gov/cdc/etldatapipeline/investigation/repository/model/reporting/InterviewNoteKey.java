package gov.cdc.etldatapipeline.investigation.repository.model.reporting;


import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.NonNull;

@Data
@NoArgsConstructor
public class InterviewNoteKey {
    @NonNull
    @JsonProperty("interview_uid")
    private Long interviewUid;
    @NonNull
    @JsonProperty("nbs_answer_uid")
    private Long nbsAnswerUid;

}
