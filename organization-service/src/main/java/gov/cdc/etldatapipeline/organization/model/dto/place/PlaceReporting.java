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
@Builder @NoArgsConstructor @AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class PlaceReporting {
    private Long placeUid;
    private String cd;
    private String placeTypeDescription;
    private String placeLocalId;
    private String placeName;
    private String placeGeneralComments;
    private String placeAddTime;
    private Long placeAddUserId;
    private String placeLastChangeTime;
    private Long placeLastChgUserId;
    private String placeRecordStatus;
    private String placeRecordStatusTime;
    private String placeStatusCd;
    private String placeStatusTime;

    private String placeQuickCode;
    private String assigningAuthorityCd;

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
}
