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
public class ProviderElasticSearch implements PersonExtendedProps {
    private Long personUid;
    private Long providerUid;
    private String additionalGenderCd;
    private String adultsInHouseNbr;
    private String asOfDateAdmin;
    private String asOfDateEthnicity;
    private String asOfDateGeneral;
    private String asOfDateMorbidity;
    private String asOfDateSex;
    private String ageReported;
    private String ageReportedUnitCd;
    private String addTime;
    private Long addUserId;
    private String birthOrderNbr;
    private String birthSex;
    private String birthTime;
    private String cd;
    private String childrenInHouseNbr;
    private String currSexCd;
    private String deceasedIndCd;
    private String deceasedTime;
    private String dedupMatchInd;
    private String description;
    private String educationLevelCd;
    private String edxInd;
    private String electronicInd;
    private String ethnicGroupInd;
    private String ethnicUnkReasonCd;
    private Long lastChgUserId;
    private String lastChgTime;
    private String localId;
    private String maritalStatusCd;
    private String multipleBirthInd;
    private String occupationCd;
    private String personFirstNm;
    private String personLastNm;
    private String personMiddleNm;
    private String personNmSuffix;
    private Long personParentUid;
    private Long pnPersonUid;
    private String preferredGenderCd;
    private String primLangCd;
    private String recordStatusCd;
    private String recordStatusTime;
    private String sexUnkReasonCd;
    private String speaksEnglishCd;
    private String statusCd;
    private String statusTime;
    private String versionCtrlNbr;


    //Name from Person_Name ODSE Table
    @JsonProperty("firstNm")
    private String firstNm;
    @JsonProperty("middleNm")
    private String middleNm;
    @JsonProperty("lastNm")
    private String lastNm;
    @JsonProperty("nmSuffix")
    private String nmSuffix;
    @JsonProperty("nmPrefix")
    private String nmPrefix;
    @JsonProperty("nmdegree")
    private String nmDegree;
    @JsonProperty("person_name_seq")
    private String personNmSeq;

    //Address
    @JsonProperty("streetAddr1")
    private String streetAddress1;
    @JsonProperty("streetAddr2")
    private String streetAddress2;
    private String city;
    private String state;
    @JsonProperty("state_desc")
    private String stateCode;
    private String zip;
    @JsonProperty("cntyCd")
    private String countyCode;
    @JsonProperty("cntryCd")
    private String countryCode;
    private String addrElpCd;
    private String addrElpUseCd;
    private Long addrPlUid;

    //Phone
    private String telephoneNbr;
    private String extensionTxt;
    private String phElpCd;
    private String phElpUseCd;
    private Long phTlUid;

    //Email
    private String email;
    private String emailElpCd;
    private String emailElpUseCd;
    private Long emailTlUid;


    //EntityId
    private String typeCd;
    private String entityRecordStatusCd;
    private Long entityUid;
    private Integer entityIdSeq;
    private String assigningAuthorityCd;
}
