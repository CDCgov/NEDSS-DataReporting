package gov.cdc.etldatapipeline.observation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ObservationMaterial {
    private Long actUid;
    private String typeCd;
    private Long materialId;
    private String subjectClassCd;
    private String recordStatus;
    private String typeDescTxt;
    private String lastChgTime;
    private String materialCd;
    private String materialNm;
    private String materialDetails;
    private String materialCollectionVol;
    private String materialCollectionVolUnit;
    private String materialDesc;
    private String riskCd;
    private String riskDescTxt;
}
