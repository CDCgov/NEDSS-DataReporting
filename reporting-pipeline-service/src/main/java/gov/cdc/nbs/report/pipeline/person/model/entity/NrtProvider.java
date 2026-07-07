package gov.cdc.nbs.report.pipeline.person.model.entity;

import static gov.cdc.nbs.report.pipeline.util.UtilHelper.parseDateTime;

import gov.cdc.nbs.report.pipeline.person.model.dto.provider.ProviderReporting;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.Data;
import lombok.NoArgsConstructor;

/** JPA entity mirroring the nrt_provider table for the person-service direct-write path. */
@Entity
@Table(name = "nrt_provider")
@Data
@NoArgsConstructor
public class NrtProvider {
  @Id
  @Column(name = "provider_uid")
  private Long providerUid;

  private String localId;
  private String recordStatus;

  @Column(name = "name_prefix")
  private String nmPrefix;

  @Column(name = "first_name")
  private String firstNm;

  @Column(name = "middle_name")
  private String middleNm;

  @Column(name = "last_name")
  private String lastNm;

  @Column(name = "name_suffix")
  private String nmSuffix;

  @Column(name = "name_degree")
  private String nmDegree;

  private String generalComments;

  @Column(name = "quick_code")
  private String providerQuickCode;

  private String providerRegistrationNum;
  private String providerRegistrationNumAuth;
  private String providerNpi;

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
  private String addressComments;
  private String phoneWork;
  private String phoneExtWork;
  private String phoneComments;
  private String phoneWorkPhone;
  private String phoneExtWorkPhone;

  @Column(name = "email_work")
  private String email;

  private String phoneCell;
  private String entryMethod;
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

  public static NrtProvider from(ProviderReporting r) {
    NrtProvider p = new NrtProvider();
    p.setProviderUid(r.getProviderUid());
    p.setLocalId(r.getLocalId());
    p.setRecordStatus(r.getRecordStatus());
    p.setNmPrefix(r.getNmPrefix());
    p.setFirstNm(r.getFirstNm());
    p.setMiddleNm(r.getMiddleNm());
    p.setLastNm(r.getLastNm());
    p.setNmSuffix(r.getNmSuffix());
    p.setNmDegree(r.getNmDegree());
    p.setGeneralComments(r.getGeneralComments());
    p.setProviderQuickCode(r.getProviderQuickCode());
    p.setProviderRegistrationNum(r.getProviderRegistrationNum());
    p.setProviderRegistrationNumAuth(r.getProviderRegistrationNumAuth());
    p.setProviderNpi(r.getProviderNpi());
    p.setStreetAddress1(r.getStreetAddress1());
    p.setStreetAddress2(r.getStreetAddress2());
    p.setCity(r.getCity());
    p.setState(r.getState());
    p.setStateCode(r.getStateCode());
    p.setZip(r.getZip());
    p.setCounty(r.getCounty());
    p.setCountyCode(r.getCountyCode());
    p.setCountry(r.getCountry());
    p.setCountryCode(r.getCountryCode());
    p.setAddressComments(r.getAddressComments());
    p.setPhoneWork(r.getPhoneWork());
    p.setPhoneExtWork(r.getPhoneExtWork());
    p.setPhoneComments(r.getPhoneComments());
    p.setPhoneWorkPhone(r.getPhoneWorkPhone());
    p.setPhoneExtWorkPhone(r.getPhoneExtWorkPhone());
    p.setEmail(r.getEmail());
    p.setPhoneCell(r.getPhoneCell());
    p.setEntryMethod(r.getEntryMethod());
    p.setAddUserId(r.getAddUserId());
    p.setAddUserName(r.getAddUserName());
    p.setAddTime(parseDateTime(r.getAddTime()));
    p.setLastChgUserId(r.getLastChgUserId());
    p.setLastChgUserName(r.getLastChgUserName());
    p.setLastChgTime(parseDateTime(r.getLastChgTime()));
    return p;
  }
}
