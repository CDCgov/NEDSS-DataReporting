package gov.cdc.etldatapipeline.postprocessingservice.repository.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;

@Data
@Entity
public class InvestigationResult {

    @Id
    @Column(name = "case_uid")
    private Long caseUid;

    @Column(name = "patient_uid")
    private Long patientUid;

    @Column(name = "investigation_key")
    private Long investigationKey;

    @Column(name = "patient_key")
    private Long patientKey;

    @Column(name = "condition_cd")
    private String conditionCd;

    @Column(name = "datamart")
    private String datamart;

    @Column(name = "stored_procedure")
    private String storedProcedure;
}
