package gov.cdc.nbs.report.pipeline.investigation.service;

import static gov.cdc.nbs.report.pipeline.util.UtilHelper.*;

import gov.cdc.nbs.report.pipeline.investigation.repository.*;
import gov.cdc.nbs.report.pipeline.investigation.repository.model.dto.*;
import gov.cdc.nbs.report.pipeline.investigation.repository.model.reporting.InvestigationKey;
import gov.cdc.nbs.report.pipeline.investigation.repository.model.reporting.InvestigationReporting;
import gov.cdc.nbs.report.pipeline.investigation.repository.model.reporting.TreatmentReportingKey;
import gov.cdc.nbs.report.pipeline.investigation.util.ProcessInvestigationDataUtil;
import gov.cdc.nbs.report.pipeline.util.DataProcessingException;
import gov.cdc.nbs.report.pipeline.util.NoDataException;
import gov.cdc.nbs.report.pipeline.util.json.CustomJsonGeneratorImpl;
import gov.cdc.nbs.report.pipeline.util.metrics.CustomMetrics;
import io.micrometer.core.instrument.Counter;
import jakarta.annotation.PostConstruct;
import jakarta.persistence.EntityNotFoundException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.ToLongFunction;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.errors.SerializationException;
import org.modelmapper.ModelMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.RetryableTopic;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.retrytopic.DltStrategy;
import org.springframework.kafka.retrytopic.TopicSuffixingStrategy;
import org.springframework.kafka.support.SendResult;
import org.springframework.kafka.support.serializer.DeserializationException;
import org.springframework.retry.annotation.Backoff;
import org.springframework.scheduling.concurrent.CustomizableThreadFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
@Setter
@RequiredArgsConstructor
public class InvestigationService {
  private static int nProc = Runtime.getRuntime().availableProcessors();

  private static final Logger logger = LoggerFactory.getLogger(InvestigationService.class);
  private ExecutorService phcExecutor =
      Executors.newFixedThreadPool(nProc * 2, new CustomizableThreadFactory("phc-"));
  private ExecutorService invExecutor;

  @Value("${spring.kafka.topics.nbs.public-health-case}")
  private String investigationTopic;

  @Value("${spring.kafka.topics.nbs.notification}")
  private String notificationTopic;

  @Value("${spring.kafka.topics.nbs.interview}")
  private String interviewTopic;

  @Value("${spring.kafka.topics.nbs.ct-contact}")
  private String contactTopic;

  @Value("${spring.kafka.topics.nbs.intervention}")
  private String vaccinationTopic;

  @Value("${spring.kafka.topics.nbs.treatment}")
  private String treatmentTopic;

  @Value("${spring.kafka.topics.nbs.act-relationship}")
  private String actRelationshipTopic;

  @Value("${spring.kafka.topics.nrt.treatment}")
  private String treatmentOutputTopicName;

  @Value("${spring.kafka.topics.nrt.investigation}")
  private String investigationTopicReporting;

  @Value("${featureFlag.phc-datamart-enable}")
  private boolean phcDatamartEnable;

  @Value("${featureFlag.thread-pool-size:1}")
  private int threadPoolSize;

  private final InvestigationRepository investigationRepository;
  private final NotificationRepository notificationRepository;
  private final InterviewRepository interviewRepository;
  private final ContactRepository contactRepository;
  private final VaccinationRepository vaccinationRepository;
  private final TreatmentRepository treatmentRepository;

  @Qualifier("investigationKafkaTemplate")
  private final KafkaTemplate<String, String> kafkaTemplate;

  private final ProcessInvestigationDataUtil processDataUtil;
  private final ModelMapper modelMapper = new ModelMapper();
  private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

  private static String topicDebugLog = "Received {} with id: {} from topic: {}";
  public static final ToLongFunction<ConsumerRecord<String, String>> toBatchId =
      rec -> rec.timestamp() + rec.offset() + rec.partition();

  InvestigationKey investigationKey = new InvestigationKey();

  private static final String SERVICE_NAME = "investigation-reporting";
  private static final String SERVICE_TAG = "service";

  private final CustomMetrics metrics;

  private Counter msgProcessed;
  private Counter msgSuccess;
  private Counter msgFailure;
  private Counter ntfFailure;

  @PostConstruct
  void initMetrics() {
    String[] tags = {SERVICE_TAG, SERVICE_NAME};

    msgProcessed = metrics.counter("inv_msg_processed", tags);
    msgSuccess = metrics.counter("inv_msg_success", tags);
    msgFailure = metrics.counter("inv_msg_failure", tags);
    ntfFailure = metrics.counter("ntf_msg_failure", tags);

    processDataUtil.setMetrics(metrics);
    invExecutor =
        Executors.newFixedThreadPool(threadPoolSize, new CustomizableThreadFactory("inv-"));
  }

  @KafkaListener(
      topics = {
        "${spring.kafka.topics.nbs.public-health-case}",
        "${spring.kafka.topics.nbs.notification}",
        "${spring.kafka.topics.nbs.interview}",
        "${spring.kafka.topics.nbs.ct-contact}",
        "${spring.kafka.topics.nbs.intervention}",
        "${spring.kafka.topics.nbs.treatment}",
        "${spring.kafka.topics.nbs.act-relationship}"
      },
      containerFactory = "investigationKafkaListenerContainerFactory")
  // BATCHING SPIKE: investigations and notifications (the volume drivers,
  // whose procs take comma-separated uid lists) are grouped into ONE proc
  // call per poll; the low-volume arms stay per-record. Retry/DLT and
  // missing-entity semantics are intentionally absent — measurement only.
  public void processMessages(List<ConsumerRecord<String, String>> records) throws Exception {
    if (records.isEmpty()) {
      return;
    }
    final long batchId = toBatchId.applyAsLong(records.get(0));
    List<String> investigationUids = new ArrayList<>();
    List<String> notificationUids = new ArrayList<>();
    List<String> interviewUids = new ArrayList<>();
    List<String> contactUids = new ArrayList<>();
    List<String> vaccinationUids = new ArrayList<>();
    List<String> treatmentUids = new ArrayList<>();
    for (ConsumerRecord<String, String> rec : records) {
      final String topic = rec.topic();
      final String message = rec.value();
      if (topic.equals(investigationTopic)) {
        final String phcUid = extractUid(message, "public_health_case_uid");
        investigationUids.add(phcUid);
        if (phcDatamartEnable) {
          CompletableFuture.runAsync(
              () -> processDataUtil.processPhcFactDatamart(phcUid), phcExecutor);
        }
      } else if (topic.equals(notificationTopic)) {
        final String notfUid = extractUid(message, "notification_uid");
        notificationUids.add(notfUid);
        if (phcDatamartEnable) {
          CompletableFuture.runAsync(
              () -> processDataUtil.processPhcFactDatamart("NOTF", notfUid), phcExecutor);
        }
      } else if (topic.equals(interviewTopic)) {
        interviewUids.add(extractUid(message, "interview_uid"));
      } else if (topic.equals(contactTopic)) {
        contactUids.add(extractUid(message, "ct_contact_uid"));
      } else if (topic.equals(vaccinationTopic)) {
        vaccinationUids.add(extractUid(message, "intervention_uid"));
      } else if (topic.equals(treatmentTopic)) {
        // Treatment topic messages only matter on update (creates arrive via
        // act_relationship), matching the original per-record gate.
        if (extractChangeDataCaptureOperation(message).equals("u")) {
          treatmentUids.add(extractUid(message, "treatment_uid"));
        }
      } else if (topic.equals(actRelationshipTopic) && message != null) {
        processActRelationship(message);
      }
    }
    logger.info("Batch: {} records -> {} investigations, {} notifications",
        records.size(), investigationUids.size(), notificationUids.size());
    if (!investigationUids.isEmpty()) {
      processInvestigationUids(String.join(",", investigationUids), batchId);
    }
    if (!notificationUids.isEmpty()) {
      processNotificationUids(String.join(",", notificationUids));
    }
    if (!interviewUids.isEmpty()) {
      processInterviewUids(String.join(",", interviewUids), batchId);
    }
    if (!contactUids.isEmpty()) {
      processContactUids(String.join(",", contactUids));
    }
    if (!vaccinationUids.isEmpty()) {
      processVaccinationUids(String.join(",", vaccinationUids));
    }
    if (!treatmentUids.isEmpty()) {
      processTreatmentUids(String.join(",", treatmentUids));
    }
  }

  // BATCHING SPIKE: one proc call for a comma-separated uid list; each result
  // row goes through the same transform/publish chain as the per-record path.
  public void processInvestigationUids(String investigationUids, long batchId) {
    metrics.recordTime(
        "inv_msg_processing_seconds",
        () -> {
          try {
            List<Investigation> investigations =
                investigationRepository.computeInvestigations(investigationUids);
            for (Investigation investigation : investigations) {
              msgProcessed.increment();
              InvestigationKey key = new InvestigationKey();
              key.setPublicHealthCaseUid(investigation.getPublicHealthCaseUid());
              InvestigationTransformed investigationTransformed =
                  processDataUtil.transformInvestigationData(investigation, batchId);
              InvestigationReporting reportingModel =
                  buildReportingModelForTransformedData(investigation, investigationTransformed);
              pushKeyValuePairToKafka(key, reportingModel, investigationTopicReporting)
                  .whenComplete((res, ex) -> msgSuccess.increment())
                  .thenRunAsync(
                      () ->
                          processDataUtil.processInvestigationCaseManagement(
                              investigation.getInvestigationCaseManagement()))
                  .thenRunAsync(
                      () ->
                          processDataUtil.processNotifications(
                              investigation.getInvestigationNotifications()))
                  .join();
            }
          } catch (Exception e) {
            msgFailure.increment();
            throw new DataProcessingException(
                errorMessage("Investigation", investigationUids, e), e);
          }
        },
        SERVICE_TAG,
        SERVICE_NAME);
  }

  private void processActRelationship(String value) {
    String sourceActUid = "";

    try {
      String typeCd;
      String operationType = extractChangeDataCaptureOperation(value);

      if (operationType.equals("d")) {
        sourceActUid = extractUid(value, "source_act_uid", "before");
        typeCd = extractValue(value, "type_cd", "before");
      } else {
        sourceActUid = extractUid(value, "source_act_uid");
        typeCd = extractValue(value, "type_cd");
      }

      logger.info(topicDebugLog, "Act_relationship", sourceActUid, actRelationshipTopic);

      if (typeCd.equals("1180")) {
        processVaccination(value, false, sourceActUid);
      }
      if (typeCd.equals("TreatmentToPHC") || typeCd.equals("TreatmentToMorb")) {
        processTreatment(value, false, sourceActUid);
      }
    } catch (Exception e) {
      throw new DataProcessingException(errorMessage("ActRelationship", sourceActUid, e), e);
    }
  }

  public void processNotificationUids(String notificationUids) {
    metrics.recordTime(
        "ntf_msg_processing_seconds",
        () -> {
          try {
            List<NotificationUpdate> notifications =
                notificationRepository.computeNotifications(notificationUids);
            for (NotificationUpdate notification : notifications) {
              processDataUtil.processNotifications(notification.getInvestigationNotifications());
            }
          } catch (Exception e) {
            ntfFailure.increment();
            throw new DataProcessingException(
                errorMessage("Notification", notificationUids, e), e);
          }
        },
        SERVICE_TAG,
        SERVICE_NAME);
  }

    private void processInterviewUids(String interviewUids, long batchId) {
    try {
      List<Interview> interviews = interviewRepository.computeInterviews(interviewUids);
      for (Interview interview : interviews) {
        processDataUtil.processInterview(interview, batchId);
        processDataUtil.processColumnMetadata(interview.getRdbCols(), interview.getInterviewUid());
      }
    } catch (Exception e) {
      throw new DataProcessingException(errorMessage("Interview", interviewUids, e), e);
    }
  }

    private void processContactUids(String contactUids) {
    try {
      List<Contact> contacts = contactRepository.computeContact(contactUids);
      for (Contact contact : contacts) {
        processDataUtil.processContact(contact);
        processDataUtil.processColumnMetadata(contact.getRdbCols(), contact.getContactUid());
      }
    } catch (Exception e) {
      throw new DataProcessingException(errorMessage("Contact", contactUids, e), e);
    }
  }

    private void processVaccinationUids(String vaccinationUids) {
    try {
      List<Vaccination> vaccinations = vaccinationRepository.computeVaccination(vaccinationUids);
      for (Vaccination vaccination : vaccinations) {
        processDataUtil.processVaccination(vaccination);
        processDataUtil.processColumnMetadata(
            vaccination.getRdbCols(), vaccination.getVaccinationUid());
      }
    } catch (Exception e) {
      throw new DataProcessingException(errorMessage("Vaccination", vaccinationUids, e), e);
    }
  }

  // Act-relationship path: single uid, with the original CDC-operation gates.
  private void processVaccination(
      String value, boolean isFromVaccinationTopic, String actRelationshipSourceActUid) {
    try {
      if (!isFromVaccinationTopic
          && extractChangeDataCaptureOperation(value).equals("u")) {
        return;
      }
      processVaccinationUids(actRelationshipSourceActUid);
    } catch (DataProcessingException e) {
      throw e;
    } catch (Exception e) {
      throw new DataProcessingException(
          errorMessage("Vaccination", actRelationshipSourceActUid, e), e);
    }
  }

    private void processTreatmentUids(String treatmentUids) {
    try {
      List<Treatment> treatments = treatmentRepository.computeTreatment(treatmentUids);
      for (Treatment treatment : treatments) {
        TreatmentReportingKey treatmentReportingKey =
            new TreatmentReportingKey(treatment.getTreatmentUid());
        String jsonKey = jsonGenerator.generateStringJson(treatmentReportingKey);
        String jsonValue = jsonGenerator.generateStringJson(treatment, "treatment_uid");
        kafkaTemplate.send(treatmentOutputTopicName, jsonKey, jsonValue);
      }
    } catch (Exception e) {
      throw new DataProcessingException(errorMessage("Treatment", treatmentUids, e), e);
    }
  }

  // Act-relationship path: single uid (any CDC operation).
  private void processTreatment(
      String value, boolean isFromTreatmentTopic, String actRelationshipSourceActUid) {
    processTreatmentUids(actRelationshipSourceActUid);
  }

  // This same method can be used for elastic search as well and that is why the generic model is
  // present
  private CompletableFuture<SendResult<String, String>> pushKeyValuePairToKafka(
      InvestigationKey investigationKey, Object model, String topicName) {
    String jsonKey = jsonGenerator.generateStringJson(investigationKey);
    String jsonValue = jsonGenerator.generateStringJson(model);
    return kafkaTemplate.send(topicName, jsonKey, jsonValue);
  }

  private InvestigationReporting buildReportingModelForTransformedData(
      Investigation investigation, InvestigationTransformed investigationTransformed) {
    final InvestigationReporting reportingModel =
        modelMapper.map(investigation, InvestigationReporting.class);
    reportingModel.setInvestigatorId(investigationTransformed.getInvestigatorId());
    reportingModel.setPhysicianId(investigationTransformed.getPhysicianId());
    reportingModel.setPatientId(investigationTransformed.getPatientId());
    reportingModel.setOrganizationId(investigationTransformed.getOrganizationId());
    reportingModel.setInvStateCaseId(
        StringUtils.hasText(investigationTransformed.getInvStateCaseId())
            ? investigationTransformed.getInvStateCaseId()
            : StringUtils.hasText(reportingModel.getInvStateCaseId())
                ? reportingModel.getInvStateCaseId()
                : null);
    reportingModel.setCityCountyCaseNbr(
        StringUtils.hasText(investigationTransformed.getCityCountyCaseNbr())
            ? investigationTransformed.getCityCountyCaseNbr()
            : StringUtils.hasText(reportingModel.getCityCountyCaseNbr())
                ? reportingModel.getCityCountyCaseNbr()
                : null);
    reportingModel.setLegacyCaseId(
        StringUtils.hasText(investigationTransformed.getLegacyCaseId())
            ? investigationTransformed.getLegacyCaseId()
            : StringUtils.hasText(reportingModel.getLegacyCaseId())
                ? reportingModel.getLegacyCaseId()
                : null);
    reportingModel.setPhcInvFormId(investigationTransformed.getPhcInvFormId());
    reportingModel.setRdbTableNameList(investigationTransformed.getRdbTableNameList());
    reportingModel.setCaseCount(investigationTransformed.getCaseCount());
    reportingModel.setInvestigationCount(investigationTransformed.getInvestigationCount());
    reportingModel.setInvestigatorAssignedDatetime(
        investigationTransformed.getInvestigatorAssignedDatetime());

    // Set hospitalUid from participation if it has not already been set from the event payload
    Optional.ofNullable(reportingModel.getHospitalUid())
        .ifPresentOrElse(
            uid -> {},
            () -> reportingModel.setHospitalUid(investigationTransformed.getHospitalUid()));
    // Set PerAsReporterOfPHC from participation if it has not already been set from the event
    // payload
    Optional.ofNullable(reportingModel.getPersonAsReporterUid())
        .ifPresentOrElse(
            uid -> {},
            () ->
                reportingModel.setPersonAsReporterUid(
                    investigationTransformed.getPersonAsReporterUid()));
    reportingModel.setDaycareFacUid(investigationTransformed.getDaycareFacUid());
    reportingModel.setChronicCareFacUid(investigationTransformed.getChronicCareFacUid());

    reportingModel.setBatchId(investigationTransformed.getBatchId());
    reportingModel.setNotes(investigation.getPhcNotes());
    return reportingModel;
  }
}
