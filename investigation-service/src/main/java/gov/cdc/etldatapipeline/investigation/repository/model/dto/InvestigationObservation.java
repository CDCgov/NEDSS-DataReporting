package gov.cdc.etldatapipeline.investigation.repository.model.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

@Data
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class InvestigationObservation {
    private Long publicHealthCaseUid;
    private Long observationId;
}
