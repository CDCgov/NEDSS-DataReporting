package gov.cdc.etldatapipeline.postprocessingservice.repository.rdb.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
@SuppressWarnings("java:S1700")
public class Datamart {
    @JsonProperty("public_health_case_uid")
    private Long publicHealthCaseUid;

    @JsonProperty("patient_uid")
    private Long patientUid;

    @JsonProperty("observation_uid")
    private Long observationUid;

    @JsonProperty("condition_cd")
    private String conditionCd;

    @JsonProperty("datamart")
    private String datamart;

    @JsonProperty("stored_procedure")
    private String storedProcedure;
}
