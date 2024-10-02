package gov.cdc.etldatapipeline.observation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ObservationNumeric {
    private Long observationUid;
    private String ovnHighRange;
    private String ovnLowRange;
    @JsonProperty("ovn_comparator_cd_1")
    private String ovnComparatorCd1;
    @JsonProperty("ovn_numeric_value_1")
    private String ovnNumericValue1;
    @JsonProperty("ovn_numeric_value_2")
    private String ovnNumericValue2;
    private String ovnNumericUnitCd;
    private String ovnSeparatorCd;
}
