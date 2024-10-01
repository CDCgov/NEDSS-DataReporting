package gov.cdc.etldatapipeline.observation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ObservationCoded {
    private Long observationUid;
    private String ovcCode;
    private String ovcCodeSystemCd;
    private String ovcCodeSystemDescTxt;
    private String ovcDisplayName;
    private String ovcAltCd;
    private String ovcAltCdDescTxt;
    private String ovcAltCdSystemCd;
    private String ovcAltCdSystemDescTxt;
}
