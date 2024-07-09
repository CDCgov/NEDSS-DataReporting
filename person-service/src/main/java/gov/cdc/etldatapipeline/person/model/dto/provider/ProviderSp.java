package gov.cdc.etldatapipeline.person.model.dto.provider;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Data Model to capture the results of the stored procedure `sp_provider_event`
 */
@Slf4j
@Data
@Builder
@Entity
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class ProviderSp {
    @Id
    @Column(name = "person_uid")
    private Long personUid;
    @Column(name = "person_parent_uid")
    private Long personParentUid;
    @Column(name = "description")
    private String description;
    @Column(name = "add_time")
    private String addTime;
    @Column(name = "first_nm")
    private String firstNm;
    @Column(name = "middle_nm")
    private String middleNm;
    @Column(name = "last_nm")
    private String lastNm;
    @Column(name = "nm_suffix")
    private String nmSuffix;
    @Column(name = "cd")
    private String cd;
    @Column(name = "electronic_ind")
    private String electronicInd;
    @Column(name = "last_chg_time")
    private String lastChgTime;
    @Column(name = "record_status_cd")
    private String recordStatusCd;
    @Column(name = "record_status_time")
    private String recordStatusTime;
    @Column(name = "status_cd")
    private String statusCd;
    @Column(name = "status_time")
    private String statusTime;
    @Column(name = "local_id")
    private String localId;
    @Column(name = "version_ctrl_nbr")
    private String versionCtrlNbr;
    @Column(name = "edx_ind")
    private String edxInd;
    @Column(name = "dedup_match_ind")
    private String dedupMatchInd;
    @Column(name = "add_user_id")
    private Long addUserId;
    @Column(name = "last_chg_user_id")
    private Long lastChgUserId;
    @Column(name = "add_user_name")
    private String addUserName;
    @Column(name = "last_chg_user_name")
    private String lastChgUserName;
    @Column(name = "provider_name")
    private String nameNested;
    @Column(name = "provider_address")
    private String addressNested;
    @Column(name = "provider_telephone")
    private String telephoneNested;
    @Column(name = "provider_email")
    private String emailNested;
    @Column(name = "provider_entity")
    private String entityDataNested;
}

