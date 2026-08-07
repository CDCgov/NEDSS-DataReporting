package gov.cdc.nbs.report.pipeline.actrelationship;

import static gov.cdc.nbs.report.pipeline.util.UtilHelper.errorMessage;
import static gov.cdc.nbs.report.pipeline.util.UtilHelper.extractChangeDataCaptureOperation;
import static gov.cdc.nbs.report.pipeline.util.UtilHelper.extractUid;
import static gov.cdc.nbs.report.pipeline.util.UtilHelper.extractValue;

import com.fasterxml.jackson.core.JsonProcessingException;
import gov.cdc.nbs.report.pipeline.investigation.service.InvestigationService;
import gov.cdc.nbs.report.pipeline.observation.service.ObservationService;
import gov.cdc.nbs.report.pipeline.util.DataProcessingException;
import org.springframework.stereotype.Component;

@Component
public class ActRelationshipProcessor {

  private final InvestigationService investigationService;
  private final ObservationService observationService;

  public ActRelationshipProcessor(
      final InvestigationService investigationService,
      final ObservationService observationService) {
    this.investigationService = investigationService;
    this.observationService = observationService;
  }

  /**
   * Examines the operation and type_cd of the incoming act_relationship message and delegates
   * processing to either the {@link InvestigationService} (for Vaccination and Treatments) or
   * {@link ObservationService} (for Observations)
   *
   * @param message The raw Kafka message retrieved by calling {@link
   *     org.apache.kafka.clients.consumer.ConsumerRecord#value()}
   */
  public void process(String message, long batchId) {
    if (message == null) {
      return;
    }

    String sourceActUid = "";
    try {
      String operationType = extractChangeDataCaptureOperation(message);

      if (operationType == null) {
        // possible tombstone message, nothing to process
        return;
      }

      // extract uid and relationship type from message
      sourceActUid = getSourceActUid(message, operationType);
      String typeCd = getTypeCd(message, operationType);

      // act_relationship entries for vaccinations and treatments are processed for all operations
      if (typeCd.equals("1180")) {
        investigationService.processVaccination(message, false, sourceActUid);
      }

      if (typeCd.equals("TreatmentToPHC") || typeCd.equals("TreatmentToMorb")) {
        investigationService.processTreatment(message, false, sourceActUid);
      }

      // act_relationship entries for observations ("OBS") are only processed for delete ("d")
      // operations
      if (operationType.equals("d")) {
        String targetClassCd = extractValue(message, "target_class_cd", "before");

        if (typeCd.equals("LabReport") && targetClassCd.equals("OBS")) {
          observationService.processObservation(message, batchId, false, sourceActUid);
        }
      }

    } catch (Exception e) {
      throw new DataProcessingException(errorMessage("ActRelationship", sourceActUid, e), e);
    }
  }

  String getSourceActUid(String message, String operationType) throws JsonProcessingException {
    if ("d".equals(operationType)) {
      return extractUid(message, "source_act_uid", "before");
    } else {
      return extractUid(message, "source_act_uid");
    }
  }

  String getTypeCd(String message, String operationType) throws JsonProcessingException {
    if ("d".equals(operationType)) {
      return extractValue(message, "type_cd", "before");
    } else {
      return extractValue(message, "type_cd");
    }
  }
}
