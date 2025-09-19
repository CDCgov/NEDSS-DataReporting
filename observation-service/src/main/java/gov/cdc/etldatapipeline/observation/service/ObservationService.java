package gov.cdc.etldatapipeline.observation.service;


import gov.cdc.etldatapipeline.commonutil.DataProcessingException;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.commonutil.metrics.CustomMetrics;
import gov.cdc.etldatapipeline.observation.repository.IObservationRepository;
import gov.cdc.etldatapipeline.observation.repository.model.dto.Observation;
import gov.cdc.etldatapipeline.observation.repository.model.reporting.ObservationKey;
import gov.cdc.etldatapipeline.observation.repository.model.dto.ObservationTransformed;
import gov.cdc.etldatapipeline.observation.repository.model.reporting.ObservationReporting;
import gov.cdc.etldatapipeline.observation.util.ProcessObservationDataUtil;
import io.micrometer.core.instrument.Counter;
import jakarta.annotation.PostConstruct;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
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
import org.springframework.kafka.support.serializer.DeserializationException;
import org.springframework.retry.annotation.Backoff;
import org.springframework.scheduling.concurrent.CustomizableThreadFactory;
import org.springframework.stereotype.Service;

import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.ToLongFunction;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.*;


@Service
@Setter
@RequiredArgsConstructor
public class ObservationService {
    private static final Logger logger = LoggerFactory.getLogger(ObservationService.class);
    private static final String BEFORE_PATH = "before";

    @Value("${spring.kafka.input.topic-name}")
    private String observationTopic;

    @Value("${spring.kafka.input.topic-name-ar}")
    private String actRelationshipTopic;

    @Value("${spring.kafka.output.topic-name-reporting}")
    private String observationTopicOutputReporting;

    @Value("${featureFlag.thread-pool-size:1}")
    private int threadPoolSize;

    private final IObservationRepository iObservationRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ProcessObservationDataUtil processObservationDataUtil;
    private final ModelMapper modelMapper = new ModelMapper();
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    private ExecutorService obsExecutor;

    private static String topicDebugLog = "Received Observation with id: {} from topic: {}";
    public static final ToLongFunction<ConsumerRecord<String, String>> toBatchId = rec -> rec.timestamp()+rec.offset()+rec.partition();

    ObservationKey observationKey = new ObservationKey();

    private static final String SERVICE_NAME = "observation-reporting";

    private final CustomMetrics metrics;

    private Counter msgProcessed;
    private Counter msgSuccess;
    private Counter msgFailure;

    @PostConstruct
    void initMetrics() {
        String[] tags = {"service", SERVICE_NAME};

        msgProcessed = metrics.counter("obs_msg_processed", tags);
        msgSuccess = metrics.counter( "obs_msg_success", tags);
        msgFailure = metrics.counter("obs_msg_failure", tags);

        obsExecutor = Executors.newFixedThreadPool(threadPoolSize, new CustomizableThreadFactory("obs-"));
    }

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
                        "${spring.kafka.input.topic-name}",
                        "${spring.kafka.input.topic-name-ar}"
                }
    )
    public CompletableFuture<Void> processMessage(ConsumerRecord<String, String> rec) {

        long batchId = toBatchId.applyAsLong(rec);
        String topic = rec.topic();
        String message = rec.value();
        logger.debug(topicDebugLog, message, topic);

        if (topic.equals(observationTopic)) {
            return CompletableFuture.runAsync(() -> processObservation(message, batchId, true, ""), obsExecutor);
        }
        else if (topic.equals(actRelationshipTopic) && message != null) {
            return CompletableFuture.runAsync(() -> processActRelationship(message, batchId), obsExecutor);
        } else {
            return CompletableFuture.failedFuture(new DataProcessingException("Received data from an unknown topic: " + topic, new NoSuchElementException()));
        }
    }

    private void processObservation(String value, long batchId, boolean isFromObservationTopic, String actRelationshipSourceActUid) {
        msgProcessed.increment();
        metrics.recordTime("obs_msg_processing_seconds", () -> {
            String observationUid = "";
            try {
                observationUid = isFromObservationTopic ? extractUid(value, "observation_uid") : actRelationshipSourceActUid;
                observationKey.setObservationUid(Long.valueOf(observationUid));
                logger.info(topicDebugLog, observationUid, observationTopic);
                Optional<Observation> observationData = iObservationRepository.computeObservations(observationUid);
                if (observationData.isPresent()) {
                    ObservationReporting reportingModel = modelMapper.map(observationData.get(), ObservationReporting.class);
                    ObservationTransformed observationTransformed = processObservationDataUtil.transformObservationData(observationData.get(), batchId);
                    modelMapper.map(observationTransformed, reportingModel);
                    pushKeyValuePairToKafka(observationKey, reportingModel, observationTopicOutputReporting);
                    logger.info("Observation data (uid={}) sent to {}", observationUid, observationTopicOutputReporting);
                    msgSuccess.increment();
                } else {
                    throw new EntityNotFoundException("Unable to find Observation with id: " + observationUid);
                }
            } catch (EntityNotFoundException ex) {
                msgFailure.increment();
                throw new NoDataException(ex.getMessage(), ex);
            } catch (Exception e) {
                msgFailure.increment();
                throw new DataProcessingException(errorMessage("Observation", observationUid, e), e);
            }
        },"service", SERVICE_NAME);
    }

    private void processActRelationship(String value, long batchId) {
        String sourceActUid = "";

        try {
            String typeCd;
            String targetClassCd;
            String operationType = extractChangeDataCaptureOperation(value);

            if (operationType.equals("d")) {
                sourceActUid = extractUid(value, "source_act_uid", BEFORE_PATH);
                typeCd = extractValue(value, "type_cd", BEFORE_PATH);
                targetClassCd = extractValue(value, "target_class_cd", BEFORE_PATH);
            }
            else {
                return;
            }

            logger.info(topicDebugLog, "Act_relationship", sourceActUid, actRelationshipTopic);
            // For LabReport values, we only need to trigger if the relationship is deleted (not covered in updates to Observation)
            // PHC targets are excluded from the LabReport association updates, as the LabReport will receive
            // an update in Observation
            if (typeCd.equals("LabReport") && targetClassCd.equals("OBS")) {
                processObservation(value, batchId, false, sourceActUid);
            }
        } catch (Exception e) {
            throw new DataProcessingException(errorMessage("ActRelationship", sourceActUid, e), e);
        }
    }



    // This same method can be used for elastic search as well and that is why the generic model is present
    private void pushKeyValuePairToKafka(ObservationKey observationKey, Object model, String topicName) {
        String jsonKey = jsonGenerator.generateStringJson(observationKey);
        String jsonValue = jsonGenerator.generateStringJson(model);
        kafkaTemplate.send(topicName, jsonKey, jsonValue);
    }
}
