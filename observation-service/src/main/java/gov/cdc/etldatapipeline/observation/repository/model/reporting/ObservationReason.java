package gov.cdc.etldatapipeline.observation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ObservationReason {
    private Long observationUid;
    private String reasonCd;
    private String reasonDescTxt;
    private Long batchId;
}
