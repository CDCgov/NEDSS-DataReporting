package gov.cdc.etldatapipeline.investigation.repository.model.dto;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;


@Entity
@Data
public class Contact {
    @Id
    @Column(name="ct_contact_uid")
    private Long contactUid;

    @Column(name="add_time")
    private String addTime;

    @Column(name="add_user_id")
    private Long addUserId;

    @Column(name="contact_entity_epi_link_id")
    private String contactEntityEpiLinkId;

    @Column(name="CONTACT_ENTITY_PHC_UID")
    private Long contactEntityPhcUid;

    @Column(name="CONTACT_ENTITY_UID")
    private Long contactEntityUid;

    @Column(name="ctt_referral_basis")
    private String cttReferralBasis;

    @Column(name="ctt_status")
    private String cttStatus;

    @Column(name="ctt_dispo_dt")
    private String cttDispoDt;

    @Column(name="ctt_disposition")
    private String cttDisposition;

    @Column(name="ctt_eval_completed")
    private String cttEvalCompleted;

    @Column(name="ctt_eval_dt")
    private String cttEvalDt;

    @Column(name="ctt_eval_notes")
    private String cttEvalNotes;

    @Column(name="ctt_group_lot_id")
    private String cttGroupLotId;

    @Column(name="ctt_health_status")
    private String cttHealthStatus;

    @Column(name="ctt_inv_assigned_dt")
    private String cttInvAssignedDt;

    @Column(name="ctt_jurisdiction_nm")
    private String cttJurisdictionNm;

    @Column(name="ctt_named_on_dt")
    private String cttNamedOnDt;

    @Column(name="ctt_notes")
    private String cttNotes;

    @Column(name="ctt_priority")
    private String cttPriority;

    @Column(name="ctt_processing_decision")
    private String cttProcessingDecision;

    @Column(name="ctt_program_area")
    private String cttProgramArea;

    @Column(name="ctt_relationship")
    private String cttRelationship;

    @Column(name="ctt_risk_ind")
    private String cttRiskInd;

    @Column(name="ctt_risk_notes")
    private String cttRiskNotes;

    @Column(name="ctt_shared_ind")
    private String cttSharedInd;

    @Column(name="ctt_symp_ind")
    private String cttSympInd;

    @Column(name="ctt_symp_notes")
    private String cttSympNotes;

    @Column(name="THIRD_PARTY_ENTITY_PHC_UID")
    private Long thirdPartyEntityPhcUid;

    @Column(name="THIRD_PARTY_ENTITY_UID")
    private Long thirdPartyEntityUid;

    @Column(name="ctt_symp_onset_dt")
    private String cttSympOnsetDt;

    @Column(name="ctt_trt_complete_ind")
    private String cttTrtCompleteInd;

    @Column(name="ctt_trt_end_dt")
    private String cttTrtEndDt;

    @Column(name="ctt_trt_initiated_ind")
    private String cttTrtInitiatedInd;

    @Column(name="ctt_trt_not_complete_rsn")
    private String cttTrtNotCompleteRsn;

    @Column(name="ctt_trt_not_start_rsn")
    private String cttTrtNotStartRsn;

    @Column(name="ctt_trt_notes")
    private String cttTrtNotes;

    @Column(name="ctt_trt_start_dt")
    private String cttTrtStartDt;

    @Column(name="last_chg_time")
    private String lastChgTime;

    @Column(name="last_chg_user_id")
    private Long lastChgUserId;

    @Column(name="local_id")
    private String localId;

    @Column(name="NAMED_DURING_INTERVIEW_UID")
    private Long namedDuringInterviewUid;

    @Column(name="program_jurisdiction_oid")
    private Long programJurisdictionOid;

    @Column(name="record_status_cd")
    private String recordStatusCd;

    @Column(name="record_status_time")
    private String recordStatusTime;

    @Column(name="subject_entity_epi_link_id")
    private String subjectEntityEpiLinkId;

    @Column(name="SUBJECT_ENTITY_PHC_UID")
    private Long subjectEntityPhcUid;

    @Column(name="version_ctrl_nbr")
    private Long versionCtrlNbr;

    @Column(name="contact_exposure_site_uid")
    private Long contactExposureSiteUid;

    @Column(name="provider_contact_investigator_uid")
    private Long providerContactInvestigatorUid;

    @Column(name="dispositioned_by_uid")
    private Long dispositionedByUid;

    @Column(name="rdb_cols")
    private String rdbCols;

    @Column(name="answers")
    private String answers;

}
