package gov.cdc.etldatapipeline.investigation.repository.model.dto;

import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class InvestigationConfirmationMethodKey {

    private Long publicHealthCaseUid;;
    private String confirmationMethodCd;

}
