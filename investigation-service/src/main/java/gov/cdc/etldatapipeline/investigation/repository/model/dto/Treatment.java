package gov.cdc.etldatapipeline.investigation.repository.model.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;

@Entity
@Data
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class Treatment {
    @Id
    @Column(name = "treatment_uid")
    private String treatmentUid;

    @Column(name = "public_health_case_uid")
    private String publicHealthCaseUid;

    @Column(name = "organization_uid")
    private String organizationUid;

    @Column(name = "provider_uid")
    private String providerUid;

    @Column(name = "patient_treatment_uid")
    private String patientTreatmentUid;

    @Column(name = "treatment_name")
    private String treatmentName;

    @Column(name = "treatment_oid")
    private String treatmentOid;

    @Column(name = "treatment_comments")
    private String treatmentComments;

    @Column(name = "treatment_shared_ind")
    private String treatmentSharedInd;

    @Column(name = "cd")
    private String cd;

    @Column(name = "treatment_date")
    private String treatmentDate;

    @Column(name = "treatment_drug")
    private String treatmentDrug;

    @Column(name = "treatment_drug_name")
    private String treatmentDrugName;

    @Column(name = "treatment_dosage_strength")
    private String treatmentDosageStrength;

    @Column(name = "treatment_dosage_strength_unit")
    private String treatmentDosageStrengthUnit;

    @Column(name = "treatment_frequency")
    private String treatmentFrequency;

    @Column(name = "treatment_duration")
    private String treatmentDuration;

    @Column(name = "treatment_duration_unit")
    private String treatmentDurationUnit;

    @Column(name = "treatment_route")
    private String treatmentRoute;

    @Column(name = "local_id")
    private String localId;

    @Column(name = "record_status_cd")
    private String recordStatusCd;

    @Column(name = "add_time")
    private String addTime;

    @Column(name = "add_user_id")
    private String addUserId;

    @Column(name = "last_chg_time")
    private String lastChangeTime;

    @Column(name = "last_chg_user_id")
    private String lastChangeUserId;

    @Column(name = "version_ctrl_nbr")
    private String versionControlNumber;
}
