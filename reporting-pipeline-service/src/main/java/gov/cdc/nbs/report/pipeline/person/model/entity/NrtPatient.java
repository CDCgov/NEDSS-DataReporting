package gov.cdc.nbs.report.pipeline.person.model.entity;

import static gov.cdc.nbs.report.pipeline.util.UtilHelper.parseBigDecimal;
import static gov.cdc.nbs.report.pipeline.util.UtilHelper.parseDateTime;

import gov.cdc.nbs.report.pipeline.person.model.dto.patient.PatientReporting;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Data;
import lombok.NoArgsConstructor;

/** JPA entity mirroring the nrt_patient table for the person-service direct-write path. */
@Entity
@Table(name = "nrt_patient")
@Data
@NoArgsConstructor
public class NrtPatient {
  @Id
  @Column(name = "patient_uid")
  private Long patientUid;

  private Long patientMprUid;
  private String recordStatus;
  private String localId;
  private String generalComments;

  @Column(name = "first_name")
  private String firstNm;

  @Column(name = "middle_name")
  private String middleNm;

  @Column(name = "last_name")
  private String lastNm;

  @Column(name = "name_suffix")
  private String nmSuffix;

  private String nmUseCd;
  private String statusNameCd;
  private String aliasNickname;

  @Column(name = "street_address_1")
  private String streetAddress1;

  @Column(name = "street_address_2")
  private String streetAddress2;

  private String city;
  private String state;
  private String stateCode;
  private String zip;
  private String county;
  private String countyCode;
  private String country;
  private String countryCode;
  private String withinCityLimits;
  private String phoneHome;
  private String phoneExtHome;
  private String phoneWork;
  private String phoneExtWork;
  private String phoneCell;
  private String email;
  private LocalDateTime dob;
  private BigDecimal ageReported;
  private String ageReportedUnit;
  private String ageReportedUnitCd;
  private String birthSex;
  private String currentSex;
  private String currSexCd;
  private String deceasedIndicator;
  private String deceasedIndCd;
  private LocalDateTime deceasedDate;
  private String maritalStatus;
  private String maritalStatusCd;
  private String ssn;
  private String ethnicGroupInd;
  private String ethnicity;
  private String raceCalculated;
  private String raceCalcDetails;

  @Column(name = "race_amer_ind_1")
  private String raceAmerInd1;

  @Column(name = "race_amer_ind_2")
  private String raceAmerInd2;

  @Column(name = "race_amer_ind_3")
  private String raceAmerInd3;

  @Column(name = "race_amer_ind_gt3_ind")
  private String raceAmerIndGt3Ind;

  @Column(name = "race_amer_ind_all")
  private String raceAmerIndAll;

  @Column(name = "race_asian_1")
  private String raceAsian1;

  @Column(name = "race_asian_2")
  private String raceAsian2;

  @Column(name = "race_asian_3")
  private String raceAsian3;

  @Column(name = "race_asian_gt3_ind")
  private String raceAsianGt3Ind;

  @Column(name = "race_asian_all")
  private String raceAsianAll;

  @Column(name = "race_black_1")
  private String raceBlack1;

  @Column(name = "race_black_2")
  private String raceBlack2;

  @Column(name = "race_black_3")
  private String raceBlack3;

  @Column(name = "race_black_gt3_ind")
  private String raceBlackGt3Ind;

  @Column(name = "race_black_all")
  private String raceBlackAll;

  @Column(name = "race_nat_hi_1")
  private String raceNatHi1;

  @Column(name = "race_nat_hi_2")
  private String raceNatHi2;

  @Column(name = "race_nat_hi_3")
  private String raceNatHi3;

  @Column(name = "race_nat_hi_gt3_ind")
  private String raceNatHiGt3Ind;

  @Column(name = "race_nat_hi_all")
  private String raceNatHiAll;

  @Column(name = "race_white_1")
  private String raceWhite1;

  @Column(name = "race_white_2")
  private String raceWhite2;

  @Column(name = "race_white_3")
  private String raceWhite3;

  @Column(name = "race_white_gt3_ind")
  private String raceWhiteGt3Ind;

  @Column(name = "race_white_all")
  private String raceWhiteAll;

  private String patientNumber;
  private String patientNumberAuth;
  private String entryMethod;
  private String speaksEnglish;
  private String unkEthnicRsn;
  private String currSexUnkRsn;
  private String preferredGender;
  private String addlGenderInfo;
  private String censusTract;
  private String raceAll;
  private String birthCountry;
  private String primaryOccupation;
  private String primaryLanguage;
  private Long addUserId;
  private String addUserName;
  private LocalDateTime addTime;
  private Long lastChgUserId;
  private String lastChgUserName;
  private LocalDateTime lastChgTime;

  // GENERATED ALWAYS AS ROW START: SQL Server populates this column; it must never be
  // included in the INSERT/UPDATE column list.
  @Column(name = "refresh_datetime", insertable = false, updatable = false)
  private LocalDateTime refreshDatetime;

  public static NrtPatient from(PatientReporting r) {
    NrtPatient p = new NrtPatient();
    p.setPatientUid(r.getPatientUid());
    p.setPatientMprUid(r.getPatientMprUid());
    p.setRecordStatus(r.getRecordStatus());
    p.setLocalId(r.getLocalId());
    p.setGeneralComments(r.getGeneralComments());
    p.setFirstNm(r.getFirstNm());
    p.setMiddleNm(r.getMiddleNm());
    p.setLastNm(r.getLastNm());
    p.setNmSuffix(r.getNmSuffix());
    p.setNmUseCd(r.getNmUseCd());
    p.setStatusNameCd(r.getStatusNameCd());
    p.setAliasNickname(r.getAliasNickname());
    p.setStreetAddress1(r.getStreetAddress1());
    p.setStreetAddress2(r.getStreetAddress2());
    p.setCity(r.getCity());
    p.setState(r.getState());
    p.setStateCode(r.getStateCode());
    p.setZip(r.getZip());
    p.setCounty(r.getCounty());
    p.setCountyCode(r.getCountyCode());
    p.setCountry(r.getHomeCountry());
    p.setCountryCode(r.getCountryCode());
    p.setWithinCityLimits(r.getWithinCityLimits());
    p.setPhoneHome(r.getPhoneHome());
    p.setPhoneExtHome(r.getPhoneExtHome());
    p.setPhoneWork(r.getPhoneWork());
    p.setPhoneExtWork(r.getPhoneExtWork());
    p.setPhoneCell(r.getPhoneCell());
    p.setEmail(r.getEmail());
    p.setDob(parseDateTime(r.getDob()));
    p.setAgeReported(parseBigDecimal(r.getAgeReported()));
    p.setAgeReportedUnit(r.getAgeReportedUnit());
    p.setAgeReportedUnitCd(r.getAgeReportedUnitCd());
    p.setBirthSex(r.getBirthSex());
    p.setCurrentSex(r.getCurrentSex());
    p.setCurrSexCd(r.getCurrSexCd());
    p.setDeceasedIndicator(r.getDeceasedIndicator());
    p.setDeceasedIndCd(r.getDeceasedIndCd());
    p.setDeceasedDate(parseDateTime(r.getDeceasedDate()));
    p.setMaritalStatus(r.getMaritalStatus());
    p.setMaritalStatusCd(r.getMaritalStatusCd());
    p.setSsn(r.getSsn());
    p.setEthnicGroupInd(r.getEthnicGroupInd());
    p.setEthnicity(r.getEthnicity());
    p.setRaceCalculated(r.getRaceCalculated());
    p.setRaceCalcDetails(r.getRaceCalcDetails());
    p.setRaceAmerInd1(r.getRaceAmerInd1());
    p.setRaceAmerInd2(r.getRaceAmerInd2());
    p.setRaceAmerInd3(r.getRaceAmerInd3());
    p.setRaceAmerIndGt3Ind(r.getRaceAmerIndGt3Ind());
    p.setRaceAmerIndAll(r.getRaceAmerIndAll());
    p.setRaceAsian1(r.getRaceAsian1());
    p.setRaceAsian2(r.getRaceAsian2());
    p.setRaceAsian3(r.getRaceAsian3());
    p.setRaceAsianGt3Ind(r.getRaceAsianGt3Ind());
    p.setRaceAsianAll(r.getRaceAsianAll());
    p.setRaceBlack1(r.getRaceBlack1());
    p.setRaceBlack2(r.getRaceBlack2());
    p.setRaceBlack3(r.getRaceBlack3());
    p.setRaceBlackGt3Ind(r.getRaceBlackGt3Ind());
    p.setRaceBlackAll(r.getRaceBlackAll());
    p.setRaceNatHi1(r.getRaceNatHi1());
    p.setRaceNatHi2(r.getRaceNatHi2());
    p.setRaceNatHi3(r.getRaceNatHi3());
    p.setRaceNatHiGt3Ind(r.getRaceNatHiGt3Ind());
    p.setRaceNatHiAll(r.getRaceNatHiAll());
    p.setRaceWhite1(r.getRaceWhite1());
    p.setRaceWhite2(r.getRaceWhite2());
    p.setRaceWhite3(r.getRaceWhite3());
    p.setRaceWhiteGt3Ind(r.getRaceWhiteGt3Ind());
    p.setRaceWhiteAll(r.getRaceWhiteAll());
    p.setPatientNumber(r.getPatientNumber());
    p.setPatientNumberAuth(r.getPatientNumberAuth());
    p.setEntryMethod(r.getEntryMethod());
    p.setSpeaksEnglish(r.getSpeaksEnglish());
    p.setUnkEthnicRsn(r.getUnkEthnicRsn());
    p.setCurrSexUnkRsn(r.getCurrSexUnkRsn());
    p.setPreferredGender(r.getPreferredGender());
    p.setAddlGenderInfo(r.getAddlGenderInfo());
    p.setCensusTract(r.getCensusTract());
    p.setRaceAll(r.getRaceAll());
    p.setBirthCountry(r.getBirthCountry());
    p.setPrimaryOccupation(r.getPrimaryOccupation());
    p.setPrimaryLanguage(r.getPrimaryLanguage());
    p.setAddUserId(r.getAddUserId());
    p.setAddUserName(r.getAddUserName());
    p.setAddTime(parseDateTime(r.getAddTime()));
    p.setLastChgUserId(r.getLastChgUserId());
    p.setLastChgUserName(r.getLastChgUserName());
    p.setLastChgTime(parseDateTime(r.getLastChgTime()));
    return p;
  }
}
