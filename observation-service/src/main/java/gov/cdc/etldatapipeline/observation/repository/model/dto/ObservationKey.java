package gov.cdc.etldatapipeline.observation.repository.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.NonNull;

@Data
@NoArgsConstructor
public class ObservationKey {
    @NonNull
    @JsonProperty("observation_uid")
    private Long observationUid;
}
