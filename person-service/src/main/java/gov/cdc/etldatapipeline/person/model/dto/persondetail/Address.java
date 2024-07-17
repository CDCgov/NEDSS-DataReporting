package gov.cdc.etldatapipeline.person.model.dto.persondetail;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import gov.cdc.etldatapipeline.person.model.dto.PersonExtendedProps;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class Address implements ExtendPerson {
    private String streetAddr1;
    private String streetAddr2;
    private String city;
    private String zip;
    private String cntyCd;
    private String state;
    private String cntryCd;
    @JsonProperty("state_desc")
    private String stateDesc;
    private String county;
    @JsonProperty("within_city_limits_ind")
    private String withinCityLimitsInd;
    private String country;
    @JsonProperty("home_country")
    private String homeCountry;
    @JsonProperty("birth_country")
    private String birthCountry;
    @JsonProperty("addr_elp_use_cd")
    private String useCd;
    @JsonProperty("addr_elp_cd")
    private String cd;
    @JsonProperty("addr_pl_uid")
    private Long postalLocatorUid;
    @JsonProperty("address_comments")
    private String addressComments;
    @JsonProperty("census_tract")
    private String censusTract;

    public <T extends PersonExtendedProps> T updatePerson(T personFull) {
        personFull.setStreetAddress1(streetAddr1);
        personFull.setStreetAddress2(streetAddr2);
        personFull.setCity(city);
        personFull.setWithinCityLimits(withinCityLimitsInd);
        personFull.setZip(zip);
        personFull.setCountyCode(cntyCd);
        personFull.setCounty(county);
        personFull.setStateCode(state);
        personFull.setState(stateDesc);
        personFull.setCountryCode(cntryCd);
        personFull.setCountry(country);
        personFull.setHomeCountry(homeCountry);
        personFull.setBirthCountry(birthCountry);
        personFull.setAddressComments(addressComments);
        personFull.setAddrElpCd(cd);
        personFull.setAddrElpUseCd(useCd);
        personFull.setAddrPlUid(postalLocatorUid);
        personFull.setCensusTract(censusTract);
        return personFull;
    }
}
