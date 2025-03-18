package gov.cdc.etldatapipeline.investigation.repository.model.reporting;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.NonNull;

@Data
@NoArgsConstructor
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class InvestigationAggregate {
    private @NonNull Long actUid;
    private @NonNull Long nbsCaseAnswerUid;
    private String answerTxt;
    private String dataType;
    private Long codeSetGroupId;
    private String datamartColumnNm;
    private Long batchId;
}
