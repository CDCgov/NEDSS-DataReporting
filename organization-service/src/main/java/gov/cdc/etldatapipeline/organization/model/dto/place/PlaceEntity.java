package gov.cdc.etldatapipeline.organization.model.dto.place;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder @AllArgsConstructor @NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class PlaceEntity implements PlaceExt<PlaceReporting> {
    private String placeQuickCode;
    private String assigningAuthorityCd;

    @Override
    public void update(PlaceReporting place) {
        place.setPlaceQuickCode(placeQuickCode);
        place.setAssigningAuthorityCd(assigningAuthorityCd);
    }
}
