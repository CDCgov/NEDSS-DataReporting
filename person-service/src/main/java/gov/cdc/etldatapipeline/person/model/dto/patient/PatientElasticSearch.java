package gov.cdc.etldatapipeline.person.model.dto.patient;

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
 * Data model for the Patient ElasticSearch target
 */
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class PatientElasticSearch implements PersonExtendedProps {
    private Long patientUid;
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
    @JsonProperty("record_status_cd")
    private String recordStatusCd;
    private String recordStatusTime;
    private String sexUnkReasonCd;
    private String speaksEnglishCd;
    private String statusCd;
    private String statusTime;
    private String versionCtrlNbr;


    //Name from Person_Name ODSE Table
    @JsonProperty("firstnm")
    private String firstNm;
    @JsonProperty("middleNm")
    private String middleNm;
    @JsonProperty("lastNm")
    private String lastNm;
    @JsonProperty("nmSuffix")
    private String nmSuffix;
    @JsonProperty("nmdegree")
    private String nmdegree;
    private String personNmSeq;
    private String nmUseCd;

    //Address
    private String streetAddress1;
    private String streetAddress2;
    private String city;
    private String state;
    private String stateCode;
    private String zip;
    private String county;
    private String countyCode;
    private String countryCode;
    private String homeCountry;
    private String withinCityLimits;
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


    //Race
    private String raceCd;
    private String raceCategory;
    private String raceDesc;
    private String raceCodeDescTxt;
    private String raceCodeParentIsCd;
    private Long prPersonUid;

    //EntityId
    @JsonProperty("typeCd")
    private String typeCd;
    @JsonProperty("recordStatusCd")
    private String entityRecordStatusCd;
    private Long entityUid;
    private Integer entityIdSeq;
    private String assigningAuthorityCd;
}
