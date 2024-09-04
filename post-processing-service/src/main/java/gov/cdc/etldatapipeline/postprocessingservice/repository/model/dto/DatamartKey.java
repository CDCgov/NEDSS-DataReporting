package gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.NonNull;

@Data
@NoArgsConstructor
public class DatamartKey {
    @NonNull
    @JsonProperty("public_health_case_uid")
    private Long publicHealthCaseUid;
}
