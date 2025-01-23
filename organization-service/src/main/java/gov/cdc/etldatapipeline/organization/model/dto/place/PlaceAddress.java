package gov.cdc.etldatapipeline.organization.model.dto.place;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
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
public class PlaceAddress implements PlaceExt<PlaceReporting> {
    private Long placePostalUid;
    private String placeZip;
    private String placeCity;
    private String placeCountry;
    @JsonProperty("place_street_address_1")
    private String placeStreetAddress1;
    @JsonProperty("place_street_address_2")
    private String placeStreetAddress2;
    private String placeCountyCode;
    private String placeStateCode;
    private String placeAddressComments;
    private String placeElpCd;
    private String placeStateDesc;
    private String placeCountyDesc;
    private String placeCountryDesc;

    @Override
    public void update(PlaceReporting place) {
        place.setPlacePostalUid(placePostalUid);
        place.setPlaceZip(placeZip);
        place.setPlaceCity(placeCity);
        place.setPlaceCountry(placeCountry);
        place.setPlaceStreetAddress1(placeStreetAddress1);
        place.setPlaceStreetAddress2(placeStreetAddress2);
        place.setPlaceCountyCode(placeCountyCode);
        place.setPlaceStateCode(placeStateCode);
        place.setPlaceAddressComments(placeAddressComments);
        place.setPlaceElpCd(placeElpCd);
        place.setPlaceStateDesc(placeStateDesc);
        place.setPlaceCountyDesc(placeCountyDesc);
        place.setPlaceCountryDesc(placeCountryDesc);
    }
}
