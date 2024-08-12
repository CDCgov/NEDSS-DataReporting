package gov.cdc.etldatapipeline.ldfdata.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.NonNull;

@Data
@NoArgsConstructor
public class LdfDataKey {
    @NonNull
    @JsonProperty("ldf_uid")
    private Long ldfUid;
}
