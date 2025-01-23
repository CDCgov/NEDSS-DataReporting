package gov.cdc.etldatapipeline.organization.model.dto.place;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.*;

@Data
@Builder @NoArgsConstructor @AllArgsConstructor
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class PlaceTeleKey {
    @NonNull
    private Long placeTeleLocatorUid;
}
