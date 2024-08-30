package gov.cdc.etldatapipeline.investigation.repository.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;

@Entity
@Data
public class InvestigationNotifications {
    @JsonProperty("source_act_uid")
    @Id
    @Column(name = "source_act_uid")
    private Long sourceActUid;

    @JsonProperty("public_health_case_uid")
    @Column(name = "public_health_case_uid")
    private Long publicHealthCaseUid;

    @JsonProperty("source_class_cd")
    @Column(name = "source_class_cd")
    private String sourceClassCd;

    @JsonProperty("target_class_cd")
    @Column(name = "target_class_cd")
    private String targetClassCd;

    @JsonProperty("act_type_cd")
    @Column(name = "act_type_cd")
    private String actTypeCd;

    @JsonProperty("status_cd")
    @Column(name = "status_cd")
    private String statusCd;

    @JsonProperty("notification_uid")
    @Column(name = "notification_uid")
    private Long notificationUid;

    @JsonProperty("prog_area_cd")
    @Column(name = "prog_area_cd")
    private String progAreaCd;

    @JsonProperty("program_jurisdiction_oid")
    @Column(name = "program_jurisdiction_oid")
    private Long programJurisdictionOid;

    @JsonProperty("jurisdiction_cd")
    @Column(name = "jurisdiction_cd")
    private String jurisdictionCd;

    @JsonProperty("record_status_time")
    @Column(name = "record_status_time")
    private String recordStatusTime;

    @JsonProperty("status_time")
    @Column(name = "status_time")
    private String statusTime;

    @JsonProperty("rpt_sent_time")
    @Column(name = "rpt_sent_time")
    private String rptSentTime;

    @JsonProperty("notif_status")
    @Column(name = "notif_status")
    private String notifStatus;

    @JsonProperty("notif_local_id")
    @Column(name = "notif_local_id")
    private String notifLocalId;

    @JsonProperty("notif_comments")
    @Column(name = "notif_comments")
    private String notifComments;

    @JsonProperty("notif_add_time")
    @Column(name = "notif_add_time")
    private String notifAddTime;

    @JsonProperty("notif_add_user_id")
    @Column(name = "notif_add_user_id")
    private Long notifAddUserId;

    @JsonProperty("notif_add_user_name")
    @Column(name = "notif_add_user_name")
    private String notifAddUserName;

    @JsonProperty("notif_last_chg_user_id")
    @Column(name = "notif_last_chg_user_id")
    private String notifLastChgUserId;

    @JsonProperty("notif_last_chg_user_name")
    @Column(name = "notif_last_chg_user_name")
    private String notifLastChgUserName;

    @JsonProperty("notif_last_chg_time")
    @Column(name = "notif_last_chg_time")
    private String notifLastChgTime;

    @JsonProperty("local_patient_id")
    @Column(name = "local_patient_id")
    private String localPatientId;

    @JsonProperty("local_patient_uid")
    @Column(name = "local_patient_uid")
    private Long localPatientUid;

    @JsonProperty("condition_cd")
    @Column(name = "condition_cd")
    private String conditionCd;

    @JsonProperty("condition_desc")
    @Column(name = "condition_desc")
    private String conditionDesc;
}

