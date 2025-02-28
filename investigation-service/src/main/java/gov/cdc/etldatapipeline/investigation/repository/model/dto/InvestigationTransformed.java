package gov.cdc.etldatapipeline.investigation.repository.model.dto;

import lombok.Data;

@Data
public class InvestigationTransformed {
    private Long publicHealthCaseUid;
    private Long investigatorId;
    private Long physicianId;
    private Long patientId;
    private Long organizationId;
    private Long hospitalUid;
    private Long daycareFacUid;
    private Long chronicCareFacUid;
    private String invStateCaseId;
    private String cityCountyCaseNbr;
    private String legacyCaseId;
    private Long phcInvFormId;
    private String rdbTableNameList;
    private Long investigationCount;
    private Long caseCount;
    private String investigatorAssignedDatetime;

    public InvestigationTransformed(Long publicHealthCaseUid) {
        this.publicHealthCaseUid = publicHealthCaseUid;
    }
}
