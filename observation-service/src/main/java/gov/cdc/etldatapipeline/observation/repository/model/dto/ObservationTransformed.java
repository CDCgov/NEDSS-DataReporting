package gov.cdc.etldatapipeline.observation.repository.model.dto;

import lombok.*;

@Data
public class ObservationTransformed {
    private Long orderingPersonId;
    private Long patientId;
    private Long performingOrganizationId;
    private Long authorOrganizationId;
    private Long orderingOrganizationId;
    private Long materialId;
    private Long resultObservationUid;
}
