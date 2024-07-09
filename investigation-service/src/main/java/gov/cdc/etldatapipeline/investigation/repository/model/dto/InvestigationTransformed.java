package gov.cdc.etldatapipeline.investigation.repository.model.dto;

import lombok.Data;

@Data
public class InvestigationTransformed {
    private Long investigatorId;
    private Long physicianId;
    private Long patientId;
    private Long organizationId;
    private String invStateCaseId;
    private String cityCountyCaseNbr;
    private String legacyCaseId;
    private Long phcInvFormId;
    private String rdbTableNameList;
}
