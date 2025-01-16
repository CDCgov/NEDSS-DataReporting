package gov.cdc.etldatapipeline.person.model.dto.user;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@Builder @NoArgsConstructor @AllArgsConstructor
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class AuthUser {
    @Id
    @Column(name = "auth_user_uid")
    private Long authUserUid;

    @Column(name = "user_id")
    private String userId;

    @Column(name = "firstNm")
    private String firstNm;

    @Column(name = "lastNm")
    private String lastNm;

    @Column(name = "nedss_entry_id")
    private Long nedssEntryId;

    @Column(name = "provider_uid")
    private Long providerUid;

    @Column(name = "add_user_id")
    private Long addUserId;

    @Column(name = "last_chg_user_id")
    private Long lastChgUserId;

    @Column(name = "add_time")
    private String addTime;

    @Column(name = "last_chg_time")
    private String lastChgTime;

    @Column(name = "record_status_cd")
    private String recordStatusCd;

    @Column(name = "record_status_time")
    private String recordStatusTime;
}
