package gov.cdc.etldatapipeline.investigation.repository.model.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class InvestigationConfirmationMethodKey {

    private Long publicHealthCaseUid;
    private String confirmationMethodCd;

}
