package gov.cdc.etldatapipeline.investigation.service;

import gov.cdc.etldatapipeline.commonutil.DataProcessingException;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.investigation.repository.*;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.*;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationKey;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationReporting;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.TreatmentReportingKey;
import gov.cdc.etldatapipeline.investigation.util.ProcessInvestigationDataUtil;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.errors.SerializationException;
import org.modelmapper.ModelMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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

import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.ToLongFunction;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.*;

@Service
@Setter
@RequiredArgsConstructor
public class InvestigationService {
    private static int nProc = Runtime.getRuntime().availableProcessors();

    private static final Logger logger = LoggerFactory.getLogger(InvestigationService.class);
    private ExecutorService phcExecutor = Executors.newFixedThreadPool(nProc*2, new CustomizableThreadFactory("phc-"));

    @Value("${spring.kafka.input.topic-name-phc}")
    private String investigationTopic;

    @Value("${spring.kafka.input.topic-name-ntf}")
    private String notificationTopic;

    @Value("${spring.kafka.input.topic-name-int}")
    private String interviewTopic;

    @Value("${spring.kafka.input.topic-name-ctr}")
    private String contactTopic;

    @Value("${spring.kafka.input.topic-name-vac}")
    private String vaccinationTopic;

    @Value("${spring.kafka.input.topic-name-tmt}")
    private String treatmentTopic;

    @Value("${spring.kafka.input.topic-name-ar}")
    private String actRelationshipTopic;

    @Value("${spring.kafka.output.topic-name-treatment}")
    private String treatmentOutputTopicName;

    @Value("${spring.kafka.output.topic-name-reporting}")
    private String investigationTopicReporting;

    @Value("${featureFlag.phc-datamart-enable}")
    private boolean phcDatamartEnable;

    @Value("${featureFlag.bmird-case-enable}")
    private boolean bmirdCaseEnable;

    @Value("${featureFlag.contact-record-enable}")
    public boolean contactRecordEnable;

    @Value("${featureFlag.treatment-enable}")
    public boolean treatmentEnable;

    private final InvestigationRepository investigationRepository;
    private final NotificationRepository notificationRepository;
    private final InterviewRepository interviewRepository;
    private final ContactRepository contactRepository;
    private final VaccinationRepository vaccinationRepository;
    private final TreatmentRepository treatmentRepository;

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ProcessInvestigationDataUtil processDataUtil;
    private final ModelMapper modelMapper = new ModelMapper();
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    private static String topicDebugLog = "Received {} with id: {} from topic: {}";
    public static final ToLongFunction<ConsumerRecord<String, String>> toBatchId = rec -> rec.timestamp()+rec.offset()+rec.partition();

    InvestigationKey investigationKey = new InvestigationKey();

    @RetryableTopic(
            attempts = "${spring.kafka.consumer.max-retry}",
            autoCreateTopics = "false",
            dltStrategy = DltStrategy.FAIL_ON_ERROR,
            retryTopicSuffix = "${spring.kafka.dlq.retry-suffix}",
            dltTopicSuffix = "${spring.kafka.dlq.dlq-suffix}",
            // retry topic name, such as topic-retry-1, topic-retry-2, etc
            topicSuffixingStrategy = TopicSuffixingStrategy.SUFFIX_WITH_INDEX_VALUE,
            // time to wait before attempting to retry
            backoff = @Backoff(delay = 1000, multiplier = 2.0),
            exclude = {
                    SerializationException.class,
                    DeserializationException.class,
                    RuntimeException.class,
                    NoDataException.class
            }
    )
    @KafkaListener(
            topics = {
                    "${spring.kafka.input.topic-name-phc}",
                    "${spring.kafka.input.topic-name-ntf}",
                    "${spring.kafka.input.topic-name-int}",
                    "${spring.kafka.input.topic-name-ctr}",
                    "${spring.kafka.input.topic-name-vac}",
                    "${spring.kafka.input.topic-name-tmt}",
                    "${spring.kafka.input.topic-name-ar}"
            }
    )
    public void processMessage(ConsumerRecord<String, String> rec,
                               Consumer<?,?> consumer) {
        String topic = rec.topic();
        String message = rec.value();
        long batchId = toBatchId.applyAsLong(rec);

        logger.debug(topicDebugLog, "message", message, topic);

        if (topic.equals(investigationTopic)) {
            processInvestigation(message, batchId);
        } else if (topic.equals(notificationTopic)) {
            processNotification(message);
        } else if (topic.equals(interviewTopic)) {
            processInterview(message, batchId);
        } else if (topic.equals(contactTopic) && contactRecordEnable) {
            processContact(message);
        } else if (topic.equals(vaccinationTopic)) {
            processVaccination(message);
        } else if (topic.equals(treatmentTopic) && treatmentEnable) {
            processTreatment(message, true, "");
        } else if (topic.equals(actRelationshipTopic) && message != null) {
            processActRelationship(message);
        }
        consumer.commitSync();
    }

    public void processInvestigation(String value, long batchId) {
        String publicHealthCaseUid = "";
        try {
            final String phcUid = publicHealthCaseUid = extractUid(value, "public_health_case_uid");

            if (phcDatamartEnable) {
                CompletableFuture.runAsync(() -> processDataUtil.processPhcFactDatamart(phcUid), phcExecutor);
            }

            // Check if feature flag for BMIRD is enabled
            final String programArea = extractValue(value, "prog_area_cd");
            if ("BMIRD".equals(programArea) && !bmirdCaseEnable) {
                return;
            }

            logger.info(topicDebugLog, "Investigation", publicHealthCaseUid, investigationTopic);
            Optional<Investigation> investigationData = investigationRepository.computeInvestigations(publicHealthCaseUid);
            if (investigationData.isPresent()) {
                Investigation investigation = investigationData.get();
                investigationKey.setPublicHealthCaseUid(Long.valueOf(publicHealthCaseUid));
                InvestigationTransformed investigationTransformed = processDataUtil.transformInvestigationData(investigation, batchId);
                InvestigationReporting reportingModel = buildReportingModelForTransformedData(investigation, investigationTransformed);
                pushKeyValuePairToKafka(investigationKey, reportingModel, investigationTopicReporting)
                        // only process and send notifications when investigation data has been sent
                        .whenComplete((res, ex) ->
                                logger.info("Investigation data (uid={}) sent to {}", phcUid, investigationTopicReporting))
                        .thenRunAsync(() -> processDataUtil.processInvestigationCaseManagement(investigation.getInvestigationCaseManagement()))
                        .thenRunAsync(() -> processDataUtil.processNotifications(investigation.getInvestigationNotifications()))
                        .join();
            } else {
                throw new EntityNotFoundException("Unable to find Investigation with id: " + publicHealthCaseUid);
            }
        } catch (EntityNotFoundException ex) {
            throw new NoDataException(ex.getMessage(), ex);
        } catch (Exception e) {
            throw new DataProcessingException(errorMessage("Investigation", publicHealthCaseUid, e), e);
        }
    }

    private void processActRelationship(String value) {
        String sourceActUid = "";

        try {
            String typeCd;
            String operationType = extractChangeDataCaptureOperation(value);

            if (operationType.equals("d")) {
                sourceActUid = extractUid(value, "source_act_uid", "before");
                typeCd = extractValue(value, "type_cd", "before");
            }
            else {
                sourceActUid = extractUid(value, "source_act_uid");
                typeCd = extractValue(value, "type_cd");
            }

            logger.info(topicDebugLog, "Act_relationship", sourceActUid, actRelationshipTopic);
            if ((typeCd.equals("TreatmentToPHC") || typeCd.equals("TreatmentToMorb")) && treatmentEnable) {
                processTreatment(value, false, sourceActUid);
            }
        } catch (Exception e) {
            throw new DataProcessingException(errorMessage("ActRelationship", sourceActUid, e), e);
        }
    }

    public void processNotification(String value) {
        String notificationUid = "";
        try {
            notificationUid = extractUid(value, "notification_uid");
            logger.info(topicDebugLog, "Notification", notificationUid, notificationTopic);

            Optional<NotificationUpdate> notificationData = notificationRepository.computeNotifications(notificationUid);
            if (notificationData.isPresent()) {
                NotificationUpdate notification = notificationData.get();
                processDataUtil.processNotifications(notification.getInvestigationNotifications());
            } else {
                throw new EntityNotFoundException("Unable to find Notification with id; " + notificationUid );
            }
        } catch (EntityNotFoundException ex) {
            throw new NoDataException(ex.getMessage(), ex);
        } catch (Exception e) {
            throw new DataProcessingException(errorMessage("Notification", notificationUid, e), e);
        }
    }


    private void processInterview(String value, long batchId) {
        String interviewUid = "";
        try {
            interviewUid = extractUid(value, "interview_uid");

            logger.info(topicDebugLog, "Interview", interviewUid, interviewTopic);
            Optional<Interview> interviewData = interviewRepository.computeInterviews(interviewUid);
            if (interviewData.isPresent()) {
                Interview interview = interviewData.get();
                processDataUtil.processInterview(interview, batchId);
                processDataUtil.processColumnMetadata(interview.getRdbCols(), interview.getInterviewUid());

            } else {
                throw new EntityNotFoundException("Unable to find Interview with id: " + interviewUid);
            }
        } catch (EntityNotFoundException ex) {
            throw new NoDataException(ex.getMessage(), ex);
        } catch (Exception e) {
            throw new DataProcessingException(errorMessage("Interview", interviewUid, e), e);
        }
    }

    private void processContact(String value) {
        String contactUid = "";
        try {
            contactUid = extractUid(value, "ct_contact_uid");

            logger.info(topicDebugLog, "Contact", contactUid, contactTopic);
            Optional<Contact> contactData = contactRepository.computeContact(contactUid);
            if(contactData.isPresent()) {
                Contact contact = contactData.get();
                processDataUtil.processContact(contact);
                processDataUtil.processColumnMetadata(contact.getRdbCols(), contact.getContactUid());
            } else {
                throw new EntityNotFoundException("Unable to find Contact with id: " + contactUid);
            }
        } catch (EntityNotFoundException ex) {
            throw new NoDataException(ex.getMessage(), ex);
        } catch (Exception e) {
            throw new DataProcessingException(errorMessage("Contact", contactUid, e), e);
        }
    }

    private void processVaccination(String value) {
        String vaccinationUid = "";
        try {
            vaccinationUid = extractUid(value, "intervention_uid");

            logger.info(topicDebugLog, "Vaccination", vaccinationUid, vaccinationTopic);
            Optional<Vaccination> vacData = vaccinationRepository.computeVaccination(vaccinationUid);
            if(vacData.isPresent()) {
                Vaccination vaccination = vacData.get();
                processDataUtil.processVaccination(vaccination);
                processDataUtil.processColumnMetadata(vaccination.getRdbCols(), vaccination.getVaccinationUid());
            } else {
                throw new EntityNotFoundException("Unable to find Vaccination with id: " + vaccinationUid);
            }
        } catch (EntityNotFoundException ex) {
            throw new NoDataException(ex.getMessage(), ex);
        } catch (Exception e) {
            throw new DataProcessingException(errorMessage("Vaccination", vaccinationUid, e), e);
        }
    }

    private void processTreatment(String value, boolean isFromTreatmentTopic, String actRelationshipSourceActUid) {
        String treatmentUid = "";
        String topic = (isFromTreatmentTopic) ? treatmentTopic : actRelationshipTopic;

        try {
            String operationType = extractChangeDataCaptureOperation(value);

            // Treatment cannot be created without an association to Investigation by default
            // Therefore, if the message comes from the treatment topic, only process if it is an update
            if (isFromTreatmentTopic) {
                if (!operationType.equals("u")) {
                    return;
                }
                treatmentUid = extractUid(value, "treatment_uid");
            }
            else {
                treatmentUid = actRelationshipSourceActUid;
            }


            logger.info(topicDebugLog, "Treatment", treatmentUid, topic);
            Optional<Treatment> treatmentData = treatmentRepository.computeTreatment(treatmentUid);
            if(treatmentData.isPresent()) {
                Treatment treatment = treatmentData.get();

                // Using Treatment directly as the reporting object
                TreatmentReportingKey treatmentReportingKey = new TreatmentReportingKey(treatment.getTreatmentUid());

                String jsonKey = jsonGenerator.generateStringJson(treatmentReportingKey);
                String jsonValue = jsonGenerator.generateStringJson(treatment,"treatment_uid");
                kafkaTemplate.send(treatmentOutputTopicName, jsonKey, jsonValue)
                        .whenComplete((res, e) -> logger.info("Treatment data (uid={}) sent to {}",
                                treatment.getTreatmentUid(), treatmentOutputTopicName));

            } else {
                throw new EntityNotFoundException("Unable to find treatment with id: " + treatmentUid);
            }
        } catch (EntityNotFoundException ex) {
            throw new NoDataException(ex.getMessage(), ex);
        } catch (Exception e) {
            throw new DataProcessingException(errorMessage("Treatment", treatmentUid, e), e);
        }
    }

    // This same method can be used for elastic search as well and that is why the generic model is present
    private CompletableFuture<SendResult<String, String>> pushKeyValuePairToKafka(InvestigationKey investigationKey, Object model, String topicName) {
        String jsonKey = jsonGenerator.generateStringJson(investigationKey);
        String jsonValue = jsonGenerator.generateStringJson(model);
        return kafkaTemplate.send(topicName, jsonKey, jsonValue);
    }

    private InvestigationReporting buildReportingModelForTransformedData(Investigation investigation, InvestigationTransformed investigationTransformed) {
        final InvestigationReporting reportingModel = modelMapper.map(investigation, InvestigationReporting.class);
        reportingModel.setInvestigatorId(investigationTransformed.getInvestigatorId());
        reportingModel.setPhysicianId(investigationTransformed.getPhysicianId());
        reportingModel.setPatientId(investigationTransformed.getPatientId());
        reportingModel.setOrganizationId(investigationTransformed.getOrganizationId());
        reportingModel.setInvStateCaseId(investigationTransformed.getInvStateCaseId());
        reportingModel.setCityCountyCaseNbr(investigationTransformed.getCityCountyCaseNbr());
        reportingModel.setLegacyCaseId(investigationTransformed.getLegacyCaseId());
        reportingModel.setPhcInvFormId(investigationTransformed.getPhcInvFormId());
        reportingModel.setRdbTableNameList(investigationTransformed.getRdbTableNameList());
        reportingModel.setCaseCount(investigationTransformed.getCaseCount());
        reportingModel.setInvestigationCount(investigationTransformed.getInvestigationCount());
        reportingModel.setInvestigatorAssignedDatetime(investigationTransformed.getInvestigatorAssignedDatetime());

        // Set hospitalUid from participation if it has not already been set from the event payload
        Optional.ofNullable(reportingModel.getHospitalUid()).ifPresentOrElse(
                uid -> {}, () -> reportingModel.setHospitalUid(investigationTransformed.getHospitalUid()));
        // Set PerAsReporterOfPHC from participation if it has not already been set from the event payload
        Optional.ofNullable(reportingModel.getPersonAsReporterUid()).ifPresentOrElse(
                uid -> {}, () -> reportingModel.setPersonAsReporterUid(investigationTransformed.getPersonAsReporterUid()));
        reportingModel.setDaycareFacUid(investigationTransformed.getDaycareFacUid());
        reportingModel.setChronicCareFacUid(investigationTransformed.getChronicCareFacUid());

        reportingModel.setBatchId(investigationTransformed.getBatchId());
        reportingModel.setNotes(investigation.getPhcNotes());
        return reportingModel;
    }
}