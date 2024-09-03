package gov.cdc.etldatapipeline.observation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ObservationReporting {
    private Long observationUid;
    @JsonProperty("obs_domain_cd_st_1")
    private String obsDomainCdSt1;
    private String classCd;
    private String moodCd;
    private Long actUid;
    private String cdDescText;
    private String recordStatusCd;
    private Long programJurisdictionOid;
    private String progAreaCd;
    private String jurisdictionCd;
    private String pregnantIndCd;
    private String localId;
    private String activityToTime;
    private String effectiveFromTime;
    private String rptToStateTime;
    private String electronicInd;
    private Integer versionCtrlNbr;
    private Long orderingPersonId;
    private Long patientId;
    private Long resultObservationUid;
    private Long authorOrganizationId;
    private Long orderingOrganizationId;
    private Long performingOrganizationId;
    private Long materialId;
    private String ctrlCdDisplayForm;
    private String processingDecisionCd;
    private String cd;
    private String sharedInd;
    private Long addUserId;
    private String addUserName;
    private String addTime;
    private Long lastChgUserId;
    private String lastChgUserName;
    private String lastChgTime;

}
