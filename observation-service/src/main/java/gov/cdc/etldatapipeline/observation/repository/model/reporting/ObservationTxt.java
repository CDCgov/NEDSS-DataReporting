package gov.cdc.etldatapipeline.observation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ObservationTxt {
    private Long observationUid;
    private Integer ovtSeq;
    private String ovtTxtTypeCd;
    private String ovtValueTxt;
    private Long batchId;
}
