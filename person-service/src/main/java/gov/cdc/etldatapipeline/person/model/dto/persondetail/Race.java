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
public class Race implements ExtendPerson {
    private String raceCd;
    private String raceDescTxt;
    private String raceCategoryCd;
    @JsonProperty("srte_code_desc_txt")
    private String srteCodeDescTxt;
    @JsonProperty("srte_parent_is_cd")
    private String srteParentIsCd;
    @JsonProperty("pr_person_uid")
    private Long personUid;
    @JsonProperty("race_calculated")
    private String raceCalculated;
    @JsonProperty("race_calc_details")
    private String raceCalcDetails;
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
    @JsonProperty("race_all")
    private String raceAll;

    public <T extends PersonExtendedProps> T updatePerson(T personFull) {
        personFull.setRaceCd(raceCd);
        personFull.setRaceCategory(raceCategoryCd);
        personFull.setRaceDesc(raceDescTxt);
        personFull.setSrteCodeDescTxt(srteCodeDescTxt);
        personFull.setSrteParentIsCd(srteParentIsCd);
        personFull.setPrPersonUid(personUid);
        personFull.setRaceCalculated(raceCalculated);
        personFull.setRaceCalcDetails(raceCalcDetails);
        personFull.setRaceAll(raceAll);
        personFull.setRaceAmerInd1(raceAmerInd1);
        personFull.setRaceAmerInd2(raceAmerInd2);
        personFull.setRaceAmerInd3(raceAmerInd3);
        personFull.setRaceAmerIndGt3Ind(raceAmerIndGt3Ind);
        personFull.setRaceAmerIndAll(raceAmerIndAll);
        personFull.setRaceAsian1(raceAsian1);
        personFull.setRaceAsian2(raceAsian2);
        personFull.setRaceAsian3(raceAsian3);
        personFull.setRaceAsianGt3Ind(raceAsianGt3Ind);
        personFull.setRaceAsianAll(raceAsianAll);
        personFull.setRaceBlack1(raceBlack1);
        personFull.setRaceBlack2(raceBlack2);
        personFull.setRaceBlack3(raceBlack3);
        personFull.setRaceBlackGt3Ind(raceBlackGt3Ind);
        personFull.setRaceBlackAll(raceBlackAll);
        personFull.setRaceNatHi1(raceNatHi1);
        personFull.setRaceNatHi2(raceNatHi2);
        personFull.setRaceNatHi3(raceNatHi3);
        personFull.setRaceNatHiGt3Ind(raceNatHiGt3Ind);
        personFull.setRaceNatHiAll(raceNatHiAll);
        personFull.setRaceWhite1(raceWhite1);
        personFull.setRaceWhite2(raceWhite2);
        personFull.setRaceWhite3(raceWhite3);
        personFull.setRaceWhiteGt3Ind(raceWhiteGt3Ind);
        personFull.setRaceWhiteAll(raceWhiteAll);

        return personFull;
    }
}
