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
    private String recordStatusCd;
    private String recordStatusTime;
    private String statusTime;
    private String jurisdictionCd;
    private Long programJurisdictionOid;
    private String progAreaCd;
    private String pregnantIndCd;
    private String localId;
    private String activityToTime;
    private String effectiveFromTime;
    private String rptToStateTime;
    private String electronicInd;
    private Integer versionCtrlNbr;
    private String ctrlCdDisplayForm;
    private String processingDecisionCd;
    private String cd;
    private String cdDescTxt;
    private String sharedInd;

    private String statusCd;
    private String cdSystemCd;
    private String cdSystemDescTxt;
    @JsonProperty("ctrl_cd_user_defined_1")
    private String ctrlCdUserDefined1;
    private String altCd;
    private String altCdDescTxt;
    private String altCdSystemCd;
    private String altCdSystemDescTxt;
    private String methodCd;
    private String methodDescTxt;
    private String targetSiteCd;
    private String targetSiteDescTxt;
    private String txt;
    private String interpretationCd;
    private String interpretationDescTxt;
    private Long reportObservationUid;
    private Long reportRefrUid;
    private Long reportSprtUid;
    private String resultObservationUid;
    private String followupObservationUid;

    private Long patientId;
    private Long orderingPersonId;
    private Long morbPhysicianId;
    private Long morbReporterId;
    private Long morbHospReporterId;
    private Long morbHospId;

    private Long transcriptionistId;
    private String transcriptionistVal;
    private String transcriptionistFirstNm;
    private String transcriptionistLastNm;
    private String transcriptionistIdAssignAuth;
    private String transcriptionistAuthType;

    private Long assistantInterpreterId;
    private String assistantInterpreterVal;
    private String assistantInterpreterFirstNm;
    private String assistantInterpreterLastNm;
    private String assistantInterpreterIdAssignAuth;
    private String assistantInterpreterAuthType;

    private Long resultInterpreterId;
    private Long specimenCollectorId;
    private Long copyToProviderId;
    private Long labTestTechnicianId;
    private Long authorOrganizationId;
    private Long orderingOrganizationId;
    private Long performingOrganizationId;
    private Long healthCareId;

    private String accessionNumber;
    private String priorityCd;
    private Long materialId;
    private Long addUserId;
    private String addUserName;
    private String addTime;
    private Long lastChgUserId;
    private String lastChgUserName;
    private String lastChgTime;
}
