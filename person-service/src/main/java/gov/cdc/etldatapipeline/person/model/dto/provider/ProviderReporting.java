package gov.cdc.etldatapipeline.person.model.dto.provider;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import gov.cdc.etldatapipeline.person.model.dto.PersonExtendedProps;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Data model for the Provider Reporting Table
 */
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ProviderReporting implements PersonExtendedProps {
    private Long providerUid;
    private String localId;
    private String recordStatus;
    private String entryMethod;
    private String generalComments;
    private Long addUserId;
    private Long lastChgUserId;
    private String addUserName;
    private String addTime;
    private String lastChgUserName;
    private String lastChgTime;

    //Name from Person_Name ODSE Table
    @JsonProperty("first_name")
    private String firstNm;
    @JsonProperty("middle_name")
    private String middleNm;
    @JsonProperty("last_name")
    private String lastNm;
    @JsonProperty("name_suffix")
    private String nmSuffix;
    @JsonProperty("name_prefix")
    private String nmPrefix;
    @JsonProperty("name_degree")
    private String nmDegree;

    //Address
    @JsonProperty("street_address_1")
    private String streetAddress1;
    @JsonProperty("street_address_2")
    private String streetAddress2;
    private String city;
    private String state;
    private String stateCode;
    private String zip;
    private String county;
    private String countyCode;
    private String country;
    private String addressComments;


    //Phone
    private String phoneWork;
    private String phoneExtWork;
    private String phoneComments;
    private String phoneCell;

    //Email
    @JsonProperty("email_work")
    private String email;

    //Entity
    @JsonProperty("quick_code")
    private String providerQuickCode;
    private String providerRegistrationNum;
    private String providerRegistrationNumAuth;
}
