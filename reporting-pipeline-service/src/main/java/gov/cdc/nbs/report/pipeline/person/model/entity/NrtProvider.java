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

  @Column(name = "local_id")
  private String localId;

  @Column(name = "record_status")
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

  @Column(name = "general_comments")
  private String generalComments;

  @Column(name = "quick_code")
  private String providerQuickCode;

  @Column(name = "provider_registration_num")
  private String providerRegistrationNum;

  @Column(name = "provider_registration_num_auth")
  private String providerRegistrationNumAuth;

  @Column(name = "provider_npi")
  private String providerNpi;

  @Column(name = "street_address_1")
  private String streetAddress1;

  @Column(name = "street_address_2")
  private String streetAddress2;

  @Column(name = "city")
  private String city;

  @Column(name = "state")
  private String state;

  @Column(name = "state_code")
  private String stateCode;

  @Column(name = "zip")
  private String zip;

  @Column(name = "county")
  private String county;

  @Column(name = "county_code")
  private String countyCode;

  @Column(name = "country")
  private String country;

  @Column(name = "country_code")
  private String countryCode;

  @Column(name = "address_comments")
  private String addressComments;

  @Column(name = "phone_work")
  private String phoneWork;

  @Column(name = "phone_ext_work")
  private String phoneExtWork;

  @Column(name = "phone_comments")
  private String phoneComments;

  @Column(name = "phone_work_phone")
  private String phoneWorkPhone;

  @Column(name = "phone_ext_work_phone")
  private String phoneExtWorkPhone;

  @Column(name = "email_work")
  private String email;

  @Column(name = "phone_cell")
  private String phoneCell;

  @Column(name = "entry_method")
  private String entryMethod;

  @Column(name = "add_user_id")
  private Long addUserId;

  @Column(name = "add_user_name")
  private String addUserName;

  @Column(name = "add_time")
  private LocalDateTime addTime;

  @Column(name = "last_chg_user_id")
  private Long lastChgUserId;

  @Column(name = "last_chg_user_name")
  private String lastChgUserName;

  @Column(name = "last_chg_time")
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
