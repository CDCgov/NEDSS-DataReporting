package gov.cdc.nbs.report.pipeline.person.model.entity;

import static gov.cdc.nbs.report.pipeline.util.UtilHelper.parseDateTime;

import gov.cdc.nbs.report.pipeline.person.model.dto.user.AuthUser;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "nrt_auth_user")
@Data
@NoArgsConstructor
public class NrtAuthUser {
  @Id
  @Column(name = "auth_user_uid")
  private Long authUserId;

  private String userId;
  private String firstNm;
  private String lastNm;
  private Long nedssEntryId;
  private Long providerUid;
  private LocalDateTime addTime;
  private Long addUserId;
  private LocalDateTime lastChgTime;
  private Long lastChgUserId;
  private String recordStatusCd;
  private LocalDateTime recordStatusTime;

  // GENERATED ALWAYS AS ROW START: SQL Server populates this column; it must never be
  // included in the INSERT/UPDATE column list.
  @Column(name = "refresh_datetime", insertable = false, updatable = false)
  private LocalDateTime refreshDatetime;

  public static NrtAuthUser from(AuthUser authUser) {
    NrtAuthUser nrtAuthUser = new NrtAuthUser();
    nrtAuthUser.setAuthUserId(authUser.getAuthUserUid());
    nrtAuthUser.setUserId(authUser.getUserId());
    nrtAuthUser.setFirstNm(authUser.getFirstNm());
    nrtAuthUser.setLastNm(authUser.getLastNm());
    nrtAuthUser.setNedssEntryId(authUser.getNedssEntryId());
    nrtAuthUser.setProviderUid(authUser.getProviderUid());
    nrtAuthUser.setAddTime(parseDateTime(authUser.getAddTime()));
    nrtAuthUser.setAddUserId(authUser.getAddUserId());
    nrtAuthUser.setLastChgTime(parseDateTime(authUser.getLastChgTime()));
    nrtAuthUser.setLastChgUserId(authUser.getLastChgUserId());
    nrtAuthUser.setRecordStatusCd(authUser.getRecordStatusCd());
    nrtAuthUser.setRecordStatusTime(parseDateTime(authUser.getRecordStatusTime()));
    return nrtAuthUser;
  }
}
