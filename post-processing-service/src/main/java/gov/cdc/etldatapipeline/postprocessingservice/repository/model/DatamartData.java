package gov.cdc.etldatapipeline.postprocessingservice.repository.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@Entity
public class DatamartData {

    @Id
    @Column(name = "public_health_case_uid")
    private Long publicHealthCaseUid;

    @Column(name = "datamart")
    private String datamart;

    @Column(name = "patient_uid")
    @EqualsAndHashCode.Exclude
    private Long patientUid;

    @Column(name = "investigation_key")
    @EqualsAndHashCode.Exclude
    private Long investigationKey;

    @Column(name = "patient_key")
    @EqualsAndHashCode.Exclude
    private Long patientKey;

    @Column(name = "condition_cd")
    @EqualsAndHashCode.Exclude
    private String conditionCd;

    @Column(name = "stored_procedure")
    @EqualsAndHashCode.Exclude
    private String storedProcedure;
}