package gov.cdc.etldatapipeline.postprocessingservice.repository.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

@Entity
@Data
@AllArgsConstructor @NoArgsConstructor
@IdClass(DatamartDataId.class)
public class DatamartData {

    @Id
    @Column(name = "public_health_case_uid")
    private Long publicHealthCaseUid;

    @Id
    @Column(name = "datamart")
    private String datamart;

    @Column(name = "patient_uid")
    @EqualsAndHashCode.Exclude
    private Long patientUid;

    @Column(name = "observation_uid")
    @EqualsAndHashCode.Exclude
    private Long observationUid;

    @Column(name = "condition_cd")
    @EqualsAndHashCode.Exclude
    private String conditionCd;

    @Column(name = "stored_procedure")
    @EqualsAndHashCode.Exclude
    private String storedProcedure;

    @Column(name = "investigation_form_cd")
    @EqualsAndHashCode.Exclude
    private String investigationFormCd;
}