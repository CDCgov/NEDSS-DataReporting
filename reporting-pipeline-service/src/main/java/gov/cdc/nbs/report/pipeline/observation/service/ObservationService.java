package gov.cdc.nbs.report.pipeline.observation.service;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.errorMessage;
import static gov.cdc.etldatapipeline.commonutil.UtilHelper.extractChangeDataCaptureOperation;
import static gov.cdc.etldatapipeline.commonutil.UtilHelper.extractUid;
import static gov.cdc.etldatapipeline.commonutil.UtilHelper.extractValue;

import com.fasterxml.jackson.core.JsonProcessingException;
import gov.cdc.etldatapipeline.commonutil.DataProcessingException;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.nbs.report.pipeline.observation.service.observation.ObservationProcessor;
import java.util.NoSuchElementException;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.ToLongFunction;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.errors.SerializationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.RetryableTopic;
import org.springframework.kafka.retrytopic.DltStrategy;
import org.springframework.kafka.retrytopic.TopicSuffixingStrategy;
import org.springframework.kafka.support.serializer.DeserializationException;
import org.springframework.retry.annotation.Backoff;
import org.springframework.scheduling.concurrent.CustomizableThreadFactory;
import org.springframework.stereotype.Service;

/**
 * Service class for processing Observation-related change events in the Real Time Reporting (RTR)
 * pipeline. This service handles the "hydration" of data for Observations by consuming Kafka events
 * from transactional source topics, transforming them, and producing them to reporting topics.
 *
 * <p>Key responsibilities include:
 *
 * <ul>
 *   <li>Consuming CDC (Change Data Capture) events for Observations and Act Relationships.
 *   <li>Fetching enriched data from the database using stored procedures.
 *   <li>Transforming raw data into reporting-optimized formats for Observation and its related
 *       entities (Coded, Date, EDX, Material, Numeric, Reason, Txt).
 *   <li>Persisting transformed data to corresponding nrt_observation_* tables
 *   <li>Pushing transformed data to corresponding output topic in Kafka.
 *   <li>Handling retries and dead-letter topics (DLT) for resilient processing.
 * </ul>
 */
@Service
public class ObservationService {
  private static final Logger logger = LoggerFactory.getLogger(ObservationService.class);
  private static final String BEFORE_PATH = "before";
  private static final String TOPIC_DEBUG_LOG = "Received Observation with id: {} from topic: {}";

  private final String observationTopic;
  private final String actRelationshipTopic;
  private final ObservationProcessor observationProcessor;
  private final ExecutorService obsExecutor;

  public ObservationService(
      final ObservationProcessor observationProcessor,
      @Value("${spring.kafka.topics.nbs.observation}") final String observationTopic,
      @Value("${spring.kafka.topics.nbs.act-relationship}") final String actRelationshipTopic,
      @Value("${featureFlag.thread-pool-size:1}") final int threadPoolSize) {
    this.observationProcessor = observationProcessor;
    this.observationTopic = observationTopic;
    this.actRelationshipTopic = actRelationshipTopic;

    obsExecutor =
        Executors.newFixedThreadPool(threadPoolSize, new CustomizableThreadFactory("obs-"));
  }

  public static final ToLongFunction<ConsumerRecord<String, String>> toBatchId =
      rec -> rec.timestamp() + rec.offset() + rec.partition();

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
      },
      kafkaTemplate = "observationKafkaTemplate")
  @KafkaListener(
      topics = {
        "${spring.kafka.topics.nbs.observation}",
        "${spring.kafka.topics.nbs.act-relationship}"
      },
      containerFactory = "observationKafkaListenerContainerFactory")
  public CompletableFuture<Void> processMessage(ConsumerRecord<String, String> rec) {

    long batchId = toBatchId.applyAsLong(rec);
    String topic = rec.topic();
    String message = rec.value();
    logger.debug(TOPIC_DEBUG_LOG, message, topic);

    if (topic.equals(observationTopic)) {
      return CompletableFuture.runAsync(() -> handleObservation(message, batchId), obsExecutor);
    } else if (topic.equals(actRelationshipTopic) && message != null) {
      return CompletableFuture.runAsync(() -> handleActRelationship(message, batchId), obsExecutor);
    } else {
      return CompletableFuture.failedFuture(
          new DataProcessingException(
              "Received data from an unknown topic: " + topic, new NoSuchElementException()));
    }
  }

  private void handleObservation(String message, long batchId) {
    try {
      String observationUid = extractUid(message, "observation_uid");
      observationProcessor.process(batchId, observationUid);
    } catch (JsonProcessingException e) {
      throw new DataProcessingException(errorMessage("Observation", "", e), e);
    }
  }

  private void handleActRelationship(String value, long batchId) {
    String sourceActUid = "";

    try {
      String typeCd;
      String targetClassCd;
      String operationType = extractChangeDataCaptureOperation(value);

      if (operationType.equals("d")) {
        sourceActUid = extractUid(value, "source_act_uid", BEFORE_PATH);
        typeCd = extractValue(value, "type_cd", BEFORE_PATH);
        targetClassCd = extractValue(value, "target_class_cd", BEFORE_PATH);
      } else {
        return;
      }

      logger.info(TOPIC_DEBUG_LOG, "Act_relationship", sourceActUid, actRelationshipTopic);
      // For LabReport values, we only need to trigger if the relationship is deleted (not covered
      // in updates to Observation)
      // PHC targets are excluded from the LabReport association updates, as the LabReport will
      // receive an update in Observation
      if (typeCd.equals("LabReport") && targetClassCd.equals("OBS")) {
        observationProcessor.process(batchId, sourceActUid);
      }
    } catch (Exception e) {
      throw new DataProcessingException(errorMessage("ActRelationship", sourceActUid, e), e);
    }
  }
}
