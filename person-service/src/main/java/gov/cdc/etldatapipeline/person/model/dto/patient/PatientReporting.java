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
 * Data model for the Patient Reporting Table
 */
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class PatientReporting implements PersonExtendedProps {
    private Long patientUid;
    private String addlGenderInfo;
    private String ageReported;
    private String ageReportedUnit;
    private String addTime;
    private Long addUserId;
    private String birth_sex;
    private String dob;
    private String currentSex;
    private String deceasedIndicator;
    private String deceasedDate;
    private String generalComments;
    private String entryMethod;
    private String ethnicity;
    private String unkEthnicRsn;
    private Long lastChgUserId;
    private String lastChgTime;
    private String localId;
    private String maritalStatus;
    private String primaryOccupation;
    private Long patientMprUid;
    private String preferredGender;
    private String primaryLanguage;
    private String recordStatus;
    private String currSexUnkRsn;
    private String speaksEnglish;

    // From Function AUTH_USR
    private String addUserName;
    private String lastChgUserName;

    //Name from Person_Name ODSE Table
    @JsonProperty("first_name")
    private String firstNm;
    @JsonProperty("middle_name")
    private String middleNm;
    @JsonProperty("last_name")
    private String lastNm;
    @JsonProperty("name_suffix")
    private String nmSuffix;
    private String aliasNickname;

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
    @JsonProperty("country")
    private String homeCountry;
    private String withinCityLimits;
    private String birthCountry;
    private String censusTract;


    //Phone
    private String phoneWork;
    private String phoneExtWork;
    private String phoneHome;
    private String PhoneExtHome;
    private String PhoneCell;

    //Email
    private String email;

    //Entity
    private String ssn;
    private String patientNumber;
    private String patientNumberAuth;

    //Race
    private String raceCalculated;
    private String raceCalcDetails;
    private String raceAll;
    @JsonProperty("race_amer_ind_1")
    private String raceAmerInd1;
    @JsonProperty("race_amer_ind_2")
    private String raceAmerInd2;
    @JsonProperty("race_amer_ind_3")
    private String raceAmerInd3;
    @JsonProperty("race_amer_ind_gt3_ind")
    private String raceAmerIndGt3Ind;
    @JsonProperty("race_amer_ind_all")
    private String raceAmerIndAll;
    @JsonProperty("race_asian_1")
    private String raceAsian1;
    @JsonProperty("race_asian_2")
    private String raceAsian2;
    @JsonProperty("race_asian_3")
    private String raceAsian3;
    @JsonProperty("race_asian_gt3_ind")
    private String raceAsianGt3Ind;
    @JsonProperty("race_asian_all")
    private String raceAsianAll;
    @JsonProperty("race_black_1")
    private String raceBlack1;
    @JsonProperty("race_black_2")
    private String raceBlack2;
    @JsonProperty("race_black_3")
    private String raceBlack3;
    @JsonProperty("race_black_gt3_ind")
    private String raceBlackGt3Ind;
    @JsonProperty("race_black_all")
    private String raceBlackAll;
    @JsonProperty("race_nat_hi_1")
    private String raceNatHi1;
    @JsonProperty("race_nat_hi_2")
    private String raceNatHi2;
    @JsonProperty("race_nat_hi_3")
    private String raceNatHi3;
    @JsonProperty("race_nat_hi_gt3_ind")
    private String raceNatHiGt3Ind;
    @JsonProperty("race_nat_hi_all")
    private String raceNatHiAll;
    @JsonProperty("race_white_1")
    private String raceWhite1;
    @JsonProperty("race_white_2")
    private String raceWhite2;
    @JsonProperty("race_white_3")
    private String raceWhite3;
    @JsonProperty("race_white_gt3_ind")
    private String raceWhiteGt3Ind;
    @JsonProperty("race_white_all")
    private String raceWhiteAll;
}
