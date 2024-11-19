package gov.cdc.etldatapipeline.investigation.repository.model.reporting;


import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class RdbMetadataColumn {
    private String tableName;
    private String rdbColumnName;
    private Integer newFlag;
    private String lastChgTime;
    private Long lastChgUserId;

}
