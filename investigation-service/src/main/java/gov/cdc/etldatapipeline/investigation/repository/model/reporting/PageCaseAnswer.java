package gov.cdc.etldatapipeline.investigation.repository.model.reporting;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.NonNull;

@Data
@NoArgsConstructor
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class PageCaseAnswer {
    private @NonNull Long actUid;
    private @NonNull Long nbsCaseAnswerUid;
    private @NonNull Long nbsUiMetadataUid;
    private @NonNull Long nbsRdbMetadataUid;
    private @NonNull Long nbsQuestionUid;

    private String rdbTableNm;
    private String rdbColumnNm;
    private String answerTxt;
    private String answerGroupSeqNbr;
    private String investigationFormCd;
    private String unitValue;
    private String questionIdentifier;
    private String dataLocation;
    private String questionLabel;
    private String otherValueIndCd;
    private String unitTypeCd;
    private String mask;
    private String dataType;
    private String questionGroupSeqNbr;
    private Long codeSetGroupId;
    private String blockNm;
    private String lastChgTime;
    private String recordStatusCd;
}