package gov.cdc.nbs.report.pipeline.person.model.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

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
    private Long lastChgUserId;
    private String recordStatusCd;
    private LocalDateTime recordStatusTime;
    @CreationTimestamp
    private LocalDateTime refreshDatetime;
}
