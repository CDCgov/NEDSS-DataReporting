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
      String operation = extractChangeDataCaptureOperation(message);

      if (operation == null) {
        // possible tombstone message, nothing to process
        return;
      }

      // extract uid and relationship type from message
      sourceActUid = getSourceActUid(message, operation);
      String typeCd = getTypeCd(message, operation);

      // call the relevant handler based on the relationship type
      if (isVaccinationRelationship(typeCd)) {
        investigationService.processVaccination(message, false, sourceActUid);
      } else if (isTreatmentRelationship(typeCd)) {
        investigationService.processTreatment(message, false, sourceActUid);
      } else if (isObservationRelationship(operation, typeCd, message)) {
        observationService.processObservation(message, batchId, false, sourceActUid);
      }

    } catch (Exception e) {
      throw new DataProcessingException(errorMessage("ActRelationship", sourceActUid, e), e);
    }
  }

  private boolean isVaccinationRelationship(String typeCd) {
    return "1180".equals(typeCd);
  }

  private boolean isTreatmentRelationship(String typeCd) {
    return "TreatmentToPHC".equals(typeCd) || "TreatmentToMorb".equals(typeCd);
  }

  private boolean isObservationRelationship(String operation, String typeCd, String message)
      throws JsonProcessingException {
    // observation relations are only processed for delete "d" messages
    if ("d".equals(operation)) {
      String targetClassCd = extractValue(message, "target_class_cd", "before");
      return typeCd.equals("LabReport") && targetClassCd.equals("OBS");
    }
    return false;
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
