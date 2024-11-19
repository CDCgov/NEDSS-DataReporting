package gov.cdc.etldatapipeline.investigation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

@Data
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class InvestigationCaseManagement {
    private Long publicHealthCaseUid;
    private Long caseManagementUid;
    private String actRefTypeCd;
    @JsonProperty("adi_900_status_cd")
    private String adi900StatusCd;
    private String adiComplexion;
    private String adiEharsId;
    private String adiHair;
    private String adiHeight;
    private String adiHeightLegacyCase;
    private String adiOtherIdentifyingInfo;
    private String adiSizeBuild;
    private String caInitIntvwrAssgnDt;
    private String caInterviewerAssignDt;
    private String caPatientIntvStatus;
    private Long caseOid;
    private String caseReviewStatus;
    private String caseReviewStatusDate;
    private String ccClosedDt;
    private String epiLinkId;
    private String fieldFollUpOojOutcome;
    private String flFupActualRefType;
    private String flFupDispoDt;
    private String flFupDispositionCd;
    private String flFupDispositionDesc;
    private String flFupExamDt;
    private String flFupExpectedDt;
    private String flFupExpectedInInd;
    private String flFupFieldRecordNum;
    private String flFupInitAssgnDt;
    private String flFupInternetOutcome;
    private String flFupInternetOutcomeCd;
    private String flFupInvestigatorAssgnDt;
    private String flFupNotificationPlanCd;
    private String flFupOojOutcome;
    private String flFupProvDiagnosis;
    private String flFupProvExmReason;
    private String fldFollUpExpectedIn;
    private String fldFollUpNotificationPlan;
    private String fldFollUpProvDiagnosis;
    private String fldFollUpProvExmReason;
    private String initFupClinicCode;
    private String initFupClosedDt;
    private String initFupInitialFollUp;
    private String initFupInitialFollUpCd;
    private String initFupInternetFollUpCd;
    private String initFollUpNotifiable;
    private String initFupNotifiableCd;
    private String initiatingAgncy;
    private String internetFollUp;
    private String oojAgency;
    private String oojDueDate;
    private String oojInitgAgncyOutcDueDate;
    private String oojInitgAgncyOutcSntDate;
    private String oojInitgAgncyRecdDate;
    private String oojNumber;
    private String patIntvStatusCd;
    @JsonProperty("status_900")
    private String status900;
    private String survClosedDt;
    private String survInvestigatorAssgnDt;
    private String survPatientFollUp;
    private String survPatientFollUpCd;
    private String survProvExmReason;
    private String survProviderContact;
    private String survProviderContactCd;
    private String survProviderDiagnosis;
    private String survProviderExamReason;
    private Long addUserId;
}