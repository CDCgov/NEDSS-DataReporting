package gov.cdc.etldatapipeline.observation.repository.model.reporting;

import lombok.Data;

@Data
public class ObservationReporting {
    private Long observationUid;
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
    private Long addUserId;
    private String addUserName;
    private String addTime;
    private Long lastChgUserId;
    private String lastChgUserName;
    private String lastChgTime;

}
