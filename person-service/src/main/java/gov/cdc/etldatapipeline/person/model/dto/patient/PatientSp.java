package gov.cdc.etldatapipeline.person.model.dto.patient;

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
 * Data Model to capture the results of the stored procedure `sp_patient_event`
 */
@Slf4j
@Data
@Builder
@Entity
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class PatientSp {
    @Id
    @Column(name = "person_uid")
    private Long personUid;
    @Column(name = "age_reported")
    private String ageReported;
    @Column(name = "age_reported_unit_cd")
    private String ageReportedUnitCd;
    @Column(name = "age_reported_unit")
    private String ageReportedUnit;
    @Column(name = "additional_gender_cd")
    private String additionalGenderCd;
    @Column(name = "add_user_id")
    private Long addUserId;
    @Column(name = "add_user_name")
    private String addUserName;
    @Column(name = "add_time")
    private String addTime;
    @Column(name = "adults_in_house_nbr")
    private String adultsInHouseNbr;
    @Column(name = "as_of_date_admin")
    private String asOfDateAdmin;
    @Column(name = "as_of_date_ethnicity")
    private String asOfDateEthnicity;
    @Column(name = "as_of_date_general")
    private String asOfDateGeneral;
    @Column(name = "as_of_date_morbidity")
    private String asOfDateMorbidity;
    @Column(name = "as_of_date_sex")
    private String asOfDateSex;
    @Column(name = "birth_gender_cd")
    private String birthGenderCd;
    @Column(name = "birth_order_nbr")
    private String birthOrderNbr;
    @Column(name = "birth_time")
    private String birthTime;
    @Column(name = "cd")
    private String cd;
    @Column(name = "children_in_house_nbr")
    private String childrenInHouseNbr;
    @Column(name = "curr_sex_cd")
    private String currSexCd;
    @Column(name = "current_sex")
    private String currentSex;
    @Column(name = "deceased_ind_cd")
    private String deceasedIndCd;
    @Column(name = "deceased_indicator")
    private String deceasedInd;
    @Column(name = "deceased_time")
    private String deceasedTime;
    @Column(name = "dedup_match_ind")
    private String dedupMatchInd;
    @Column(name = "description")
    private String description;
    @Column(name = "education_level_cd")
    private String educationLevelCd;
    @Column(name = "edx_ind")
    private String edxInd;
    @Column(name = "electronic_ind")
    private String electronicInd;
    @Column(name = "ethnic_group_ind")
    private String ethnicGroupInd;
    @Column(name = "ethnicity")
    private String ethnicity;
    @Column(name = "ethnic_unk_reason_cd")
    private String ethnicUnkReasonCd;
    @Column(name = "unk_ethnic_rsn")
    private String ethnicUnkReason;
    @Column(name = "last_chg_time")
    private String lastChgTime;
    @Column(name = "last_chg_user_id")
    private Long lastChgUserId;
    @Column(name = "last_chg_user_name")
    private String lastChgUserName;
    @Column(name = "local_id")
    private String localId;
    @Column(name = "marital_status_cd")
    private String maritalStatusCd;
    @Column(name = "marital_status")
    private String maritalStatus;
    @Column(name = "multiple_birth_ind")
    private String multipleBirthInd;
    @Column(name = "occupation_cd")
    private String occupationCd;
    @Column(name = "primary_occupation")
    private String primaryOccupation;
    @Column(name = "person_parent_uid")
    private Long personParentUid;
    @Column(name = "first_nm")
    private String personFirstNm;
    @Column(name = "last_nm")
    private String personLastNm;
    @Column(name = "middle_nm")
    private String personMiddleNm;
    @Column(name = "nm_suffix")
    private String personNmSuffix;
    @Column(name = "preferred_gender_cd")
    private String preferredGenderCd;
    @Column(name = "preferred_gender")
    private String preferredGender;
    @Column(name = "prim_lang_cd")
    private String primLangCd;
    @Column(name = "record_status_cd")
    private String recordStatusCd;
    @Column(name = "record_status_time")
    private String recordStatusTime;
    @Column(name = "status_cd")
    private String statusCd;
    @Column(name = "speaks_english_cd")
    private String speaksEnglishCd;
    @Column(name = "speaks_english")
    private String speaksEnglish;
    @Column(name = "status_time")
    private String statusTime;
    @Column(name = "sex_unk_reason_cd")
    private String sexUnkReasonCd;
    @Column(name = "version_ctrl_nbr")
    private String versionCtrlNbr;

    //Following are Json data formatted nested fields
    @Column(name = "patient_name")
    private String nameNested;
    @Column(name = "patient_address")
    private String addressNested;
    @Column(name = "patient_race")
    private String raceNested;
    @Column(name = "patient_telephone")
    private String telephoneNested;
    @Column(name = "patient_email")
    private String emailNested;
    @Column(name = "patient_entity")
    private String entityDataNested;
}
