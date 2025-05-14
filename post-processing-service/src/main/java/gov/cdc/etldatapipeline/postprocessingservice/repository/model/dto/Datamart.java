package gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class Datamart {
    @JsonProperty("public_health_case_uid")
    private Long publicHealthCaseUid;

    @JsonProperty("patient_uid")
    private Long patientUid;

    @JsonProperty("observation_uid")
    private Long observationUid;

    @JsonProperty("vaccination_uid")
    private Long vaccinationUid;

    @JsonProperty("condition_cd")
    private String conditionCd;

    @JsonProperty("datamart")
    private String datamart;

    @JsonProperty("stored_procedure")
    private String storedProcedure;
}
