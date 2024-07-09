package gov.cdc.etldatapipeline.investigation.repository.model.dto;

import lombok.Data;

@Data
public class InvestigationObservation {
    private Long publicHealthCaseUid;
    private Long observationId;
}
