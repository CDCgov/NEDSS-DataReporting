package gov.cdc.etldatapipeline.investigation.repository.model.reporting;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class InterviewReporting {
    private Long interviewUid;
    private String interviewStatusCd;
    private String interviewDate;
    private String intervieweeRoleCd;
    private String interviewTypeCd;
    private String interviewLocCd;
    private String localId;
    private String recordStatusCd;
    private String recordStatusTime;
    private String addTime;
    private Long addUserId;
    private String lastChgTime;
    private Long lastChgUserId;
    private Long versionCtrlNbr;
    private String ixStatus;
    private String ixIntervieweeRole;
    private String ixType;
    private String ixLocation;
    private Long investigationUid;
    private Long providerUid;
    private Long organizationUid;
    private Long patientUid;
}
