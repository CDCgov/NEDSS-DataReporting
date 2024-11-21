package gov.cdc.etldatapipeline.investigation.repository.model.dto;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;

@Entity
@Data
public class Interview {
    @Id
    @Column(name="interview_uid")
    private Long interviewUid;

    @Column(name="interview_status_cd")
    private String interviewStatusCd;

    @Column(name="interview_date")
    private String interviewDate;

    @Column(name="interviewee_role_cd")
    private String intervieweeRoleCd;

    @Column(name="interview_type_cd")
    private String interviewTypeCd;

    @Column(name="interview_loc_cd")
    private String interviewLocCd;

    @Column(name="local_id")
    private String localId;

    @Column(name="record_status_cd")
    private String recordStatusCd;

    @Column(name="record_status_time")
    private String recordStatusTime;

    @Column(name="add_time")
    private String addTime;

    @Column(name="add_user_id")
    private Long addUserId;

    @Column(name="last_chg_time")
    private String lastChgTime;

    @Column(name="last_chg_user_id")
    private Long lastChgUserId;

    @Column(name="version_ctrl_nbr")
    private Long versionCtrlNbr;

    @Column(name="ix_status")
    private String ixStatus;

    @Column(name="ix_interviewee_role")
    private String ixIntervieweeRole;

    @Column(name="ix_type")
    private String ixType;

    @Column(name="ix_location")
    private String ixLocation;

    @Column(name="investigation_uid")
    private String investigationUid;

    @Column(name="provider_uid")
    private String providerUid;

    @Column(name="organization_uid")
    private String organizationUid;

    @Column(name="patient_uid")
    private String patientUid;

    @Column(name="answers")
    private String answers;

    @Column(name="notes")
    private String notes;

    @Column(name="rdb_cols")
    private String rdbCols;

}

