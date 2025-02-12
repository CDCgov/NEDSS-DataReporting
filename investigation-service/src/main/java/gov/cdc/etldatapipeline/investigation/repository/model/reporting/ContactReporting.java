package gov.cdc.etldatapipeline.investigation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ContactReporting {
    private Long contactUid;
    private String addTime;
    private Long addUserId;
    private String contactEntityEpiLinkId;
    private Long contactEntityPhcUid;
    private Long contactEntityUid;
    private String cttReferralBasis;
    private String cttStatus;
    private String cttDispoDt;
    private String cttDisposition;
    private String cttEvalCompleted;
    private String cttEvalDt;
    private String cttEvalNotes;
    private String cttGroupLotId;
    private String cttHealthStatus;
    private String cttInvAssignedDt;
    private String cttJurisdictionNm;
    private String cttNamedOnDt;
    private String cttNotes;
    private String cttPriority;
    private String cttProcessingDecision;
    private String cttProgramArea;
    private String cttRelationship;
    private String cttRiskInd;
    private String cttRiskNotes;
    private String cttSharedInd;
    private String cttSympInd;
    private String cttSympNotes;
    private String cttSympOnsetDt;
    private Long thirdPartyEntityPhcUid;
    private Long thirdPartyEntityUid;
    private String cttTrtCompleteInd;
    private String cttTrtEndDt;
    private String cttTrtInitiatedInd;
    private String cttTrtNotCompleteRsn;
    private String cttTrtNotStartRsn;
    private String cttTrtNotes;
    private String cttTrtStartDt;
    private String lastChgTime;
    private Long lastChgUserId;
    private String localId;
    private Long namedDuringInterviewUid;
    private Long programJurisdictionOid;
    private String recordStatusCd;
    private String recordStatusTime;
    private String subjectEntityEpiLinkId;
    private Long subjectEntityPhcUid;
    private Long versionCtrlNbr;
    private Long contactExposureSiteUid;
    private Long providerContactInvestigatorUid;
    private Long dispositionedByUid;
}
