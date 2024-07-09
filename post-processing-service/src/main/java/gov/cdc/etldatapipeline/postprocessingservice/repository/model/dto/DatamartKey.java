package gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Data;
import lombok.NonNull;

@Data
@Builder
public class DatamartKey {
    @NonNull
    @JsonProperty("public_health_case_uid")
    private Long publicHealthCaseUid;
}
