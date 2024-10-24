package gov.cdc.etldatapipeline.investigation.service;

import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.NotificationUpdate;
import gov.cdc.etldatapipeline.investigation.repository.InvestigationRepository;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.Investigation;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationKey;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.InvestigationTransformed;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationReporting;
import gov.cdc.etldatapipeline.investigation.repository.NotificationRepository;
import gov.cdc.etldatapipeline.investigation.util.ProcessInvestigationDataUtil;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.apache.kafka.clients.consumer.Consumer;
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
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.kafka.support.SendResult;
import org.springframework.kafka.support.serializer.DeserializationException;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.retry.annotation.Backoff;
import org.springframework.scheduling.concurrent.CustomizableThreadFactory;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.extractUid;

@Service
@Setter
@RequiredArgsConstructor
public class InvestigationService {
    private static int nProc = Runtime.getRuntime().availableProcessors();

    private static final Logger logger = LoggerFactory.getLogger(InvestigationService.class);
    private final ExecutorService phcExecutor = Executors.newFixedThreadPool(nProc*2, new CustomizableThreadFactory("phc-"));

    @Value("${spring.kafka.input.topic-name-phc}")
    private String investigationTopic;

    @Value("${spring.kafka.input.topic-name-ntf}")
    private String notificationTopic;

    @Value("${spring.kafka.output.topic-name-reporting}")
    public String investigationTopicReporting;

    @Value("${service.phc-datamart-enable}")
    public boolean phcDatamartEnable;

    private final InvestigationRepository investigationRepository;
    private final NotificationRepository notificationRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ProcessInvestigationDataUtil processDataUtil;
    InvestigationKey investigationKey = new InvestigationKey();
    private final ModelMapper modelMapper = new ModelMapper();
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    private static String topicDebugLog = "Received {} with id: {} from topic: {}";

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
                    "${spring.kafka.input.topic-name-ntf}"
            }
    )
    public void processMessage(String message,
                               @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
                               Consumer<?,?> consumer) {
        logger.debug(topicDebugLog, "message", message, topic);
        if (topic.equals(investigationTopic)) {
            processInvestigation(message);
        } else if (topic.equals(notificationTopic)) {
            processNotification(message);
        }
        consumer.commitSync();
    }

    public void processInvestigation(String value) {
        String publicHealthCaseUid = "";
        try {
            final String phcUid = publicHealthCaseUid = extractUid(value, "public_health_case_uid");

            if (phcDatamartEnable) {
                CompletableFuture.runAsync(() -> processDataUtil.processPhcFactDatamart(phcUid), phcExecutor);
            }

            logger.info(topicDebugLog, "Investigation", publicHealthCaseUid, investigationTopic);
            Optional<Investigation> investigationData = investigationRepository.computeInvestigations(publicHealthCaseUid);
            if (investigationData.isPresent()) {
                Investigation investigation = investigationData.get();
                investigationKey.setPublicHealthCaseUid(Long.valueOf(publicHealthCaseUid));
                InvestigationTransformed investigationTransformed = processDataUtil.transformInvestigationData(investigation);
                InvestigationReporting reportingModel = buildReportingModelForTransformedData(investigation, investigationTransformed);
                pushKeyValuePairToKafka(investigationKey, reportingModel, investigationTopicReporting)
                        // only process and send notifications when investigation data has been sent
                        .whenComplete((res, ex) ->
                                logger.info("Investigation data (uid={}) sent to {}", phcUid, investigationTopicReporting))
                        .thenRunAsync(() -> processDataUtil.processNotifications(investigation.getInvestigationNotifications()))
                        .join();
            } else {
                throw new EntityNotFoundException("Unable to find Investigation with id: " + publicHealthCaseUid);
            }
        } catch (EntityNotFoundException ex) {
            throw new NoDataException(ex.getMessage(), ex);
        } catch (Exception e) {
            String msg = "Error processing Investigation data" +
                    (!publicHealthCaseUid.isEmpty() ? " with ids '" + publicHealthCaseUid + "': " : ": " + e.getMessage());
            throw new RuntimeException(msg, e);
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
            String msg = "Error processing Notification data" +
                (!notificationUid.isEmpty() ? " for ids='" + notificationUid + "': " : ": " + e.getMessage());
            throw new RuntimeException(msg, e);
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
        return reportingModel;
    }
}