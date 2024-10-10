package gov.cdc.etldatapipeline.observation.repository.model.dto;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Getter;
import lombok.Setter;

@Entity
@Getter
@Setter
public class Observation {

    @Column(name = "act_uid")
    private Long actUid;

    @Column(name = "class_cd")
    private String classCd;

    @Column(name = "mood_cd")
    private String moodCd;

    @Column(name = "interpretation_cd")
    private String interpretationCd;

    @Column(name = "interpretation_desc_txt")
    private String interpretationDescTxt;

    @Id
    @Column(name = "observation_uid")
    private Long observationUid;

    @Column(name = "obs_domain_cd_st_1")
    private String obsDomainCdSt1;

    @Column(name = "cd_desc_txt")
    private String cdDescTxt;

    @Column(name = "record_status_cd")
    private String recordStatusCd;

    @Column(name = "program_jurisdiction_oid")
    private Long programJurisdictionOid;

    @Column(name = "prog_area_cd")
    private String progAreaCd;

    @Column(name = "jurisdiction_cd")
    private String jurisdictionCd;

    @Column(name = "pregnant_ind_cd")
    private String pregnantIndCd;

    @Column(name = "local_id")
    private String localId;

    @Column(name = "activity_to_time")
    private String activityToTime;

    @Column(name = "effective_from_time")
    private String effectiveFromTime;

    @Column(name = "rpt_to_state_time")
    private String rptToStateTime;

    @Column(name = "electronic_ind")
    private Character electronicInd;

    @Column(name = "version_ctrl_nbr")
    private Short versionCtrlNbr;

    @Column(name = "ctrl_cd_display_form")
    private String ctrlCdDisplayForm;

    @Column(name = "processing_decision_cd")
    private String processingDecisionCd;

    @Column(name = "cd")
    private String cd;

    @Column(name = "shared_ind")
    private Character sharedInd;

    @Column(name = "status_cd")
    private String statusCd;

    @Column(name = "cd_system_cd")
    private String cdSystemCd;

    @Column(name = "cd_system_desc_txt")
    private String cdSystemDescTxt;

    @Column(name = "ctrl_cd_user_defined_1")
    private String ctrlCdUserDefined1;

    @Column(name = "alt_cd")
    private String altCd;

    @Column(name = "alt_cd_desc_txt")
    private String altCdDescTxt;

    @Column(name = "alt_cd_system_cd")
    private String altCdSystemCd;

    @Column(name = "alt_cd_system_desc_txt")
    private String altCdSystemDescTxt;

    @Column(name = "method_cd")
    private String methodCd;

    @Column(name = "method_desc_txt")
    private String methodDescTxt;

    @Column(name = "target_site_cd")
    private String targetSiteCd;

    @Column(name = "target_site_desc_txt")
    private String targetSiteDescTxt;

    @Column(name = "txt")
    private String txt;

    @Column(name = "priority_cd")
    private String priorityCd;

    @Column(name = "add_user_id")
    private Long addUserId;

    @Column(name = "add_user_name")
    private String addUserName;

    @Column(name = "last_chg_user_id")
    private Long lastChgUserId;

    @Column(name = "last_chg_user_name")
    private String lastChgUserName;

    @Column(name = "add_time")
    private String addTime;

    @Column(name = "last_chg_time")
    private String lastChgTime;

    @Column(name = "person_participations")
    private String personParticipations;

    @Column(name = "organization_participations")
    private String organizationParticipations;

    @Column(name = "material_participations")
    private String materialParticipations;

    @Column(name = "followup_observations")
    private String followupObservations;

    @Column(name = "parent_observations")
    private String parentObservations;

    @Column(name = "act_ids")
    private String actIds;

    @Column(name = "edx_ids")
    private String edxIds;

    @Column(name = "obs_reason")
    private String obsReason;

    @Column(name = "obs_txt")
    private String obsTxt;

    @Column(name = "obs_code")
    private String obsCode;

    @Column(name = "obs_date")
    private String obsDate;

    @Column(name = "obs_num")
    private String obsNum;
}
