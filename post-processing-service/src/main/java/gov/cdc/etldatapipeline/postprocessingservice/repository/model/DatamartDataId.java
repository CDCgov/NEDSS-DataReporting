package gov.cdc.etldatapipeline.postprocessingservice.repository.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.Getter;
import lombok.Setter;

@Embeddable
@Getter @Setter
public class DatamartDataId {

    @Column(name = "public_health_case_uid")
    private Long publicHealthCaseUid;

    @Column(name = "datamart")
    private String datamart;

}
