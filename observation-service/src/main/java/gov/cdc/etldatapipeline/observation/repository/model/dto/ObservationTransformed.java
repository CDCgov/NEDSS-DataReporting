package gov.cdc.etldatapipeline.observation.repository.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@Data
public class ObservationTransformed {
    private Long observationUid;
    private Long reportObservationUid;
    private Long reportSprtUid;
    private Long reportRefrUid;
    private String resultObservationUid;
    private String followUpObservationUid;

    private Long patientId;
    private String orderingPersonId;
    private Long morbPhysicianId;
    private Long morbReporterId;
    private Long morbHospReporterId;
    private Long morbHospId;

    private Long transcriptionistId;
    private String transcriptionistVal;
    private String transcriptionistFirstNm;
    private String transcriptionistLastNm;
    private String transcriptionistIdAssignAuth;
    private String transcriptionistAuthType;

    private Long assistantInterpreterId;
    private String assistantInterpreterVal;
    private String assistantInterpreterFirstNm;
    private String assistantInterpreterLastNm;
    private String assistantInterpreterIdAssignAuth;
    private String assistantInterpreterAuthType;

    private Long resultInterpreterId;
    private Long specimenCollectorId;
    private Long copyToProviderId;
    private Long labTestTechnicianId;
    private Long authorOrganizationId;
    private Long orderingOrganizationId;
    private Long performingOrganizationId;
    private Long healthCareId;

    private String accessionNumber;
    private Long materialId;

    @JsonProperty("device_instance_id_1")
    private String deviceInstanceId1;
    @JsonProperty("device_instance_id_2")
    private String deviceInstanceId2;

    private Long batchId;
}
