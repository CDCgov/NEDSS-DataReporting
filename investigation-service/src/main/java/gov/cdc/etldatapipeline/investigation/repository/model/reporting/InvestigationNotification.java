package gov.cdc.etldatapipeline.investigation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class InvestigationNotification {
    private Long sourceActUid;
    private Long publicHealthCaseUid;
    private String sourceClassCd;
    private String targetClassCd;
    private String actTypeCd;
    private String statusCd;
    private Long notificationUid;
    private String progAreaCd;
    private Long programJurisdictionOid;
    private String jurisdictionCd;
    private String recordStatusTime;
    private String statusTime;
    private String rptSentTime;
    private String notifStatus;
    private String notifLocalId;
    private String notifComments;
    private String notifAddTime;
    private Long notifAddUserId;
    private String notifAddUserName;
    private String notifLastChgUserId;
    private String notifLastChgUserName;
    private String notifLastChgTime;
    private String localPatientId;
    private Long localPatientUid;
    private String conditionCd;
    private String conditionDesc;
}

