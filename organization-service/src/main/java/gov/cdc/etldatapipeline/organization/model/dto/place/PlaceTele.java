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
public class PlaceTele {
    private Long placeUid;
    private Long placeTeleLocatorUid;
    private String placePhoneExt;
    private String placePhone;
    private String placeEmail;
    private String placePhoneComments;
    private String teleUseCd;
    private String teleCd;
    private String placeTeleType;
    private String placeTeleUse;
}
