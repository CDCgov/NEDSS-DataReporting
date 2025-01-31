package gov.cdc.etldatapipeline.postprocessingservice.repository.model;

import jakarta.persistence.*;
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

    @Column(name = "condition_cd")
    @EqualsAndHashCode.Exclude
    private String conditionCd;

    @Column(name = "stored_procedure")
    @EqualsAndHashCode.Exclude
    private String storedProcedure;
}