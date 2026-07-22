package gov.cdc.nbs.report.pipeline.observation.service;

import static gov.cdc.nbs.report.pipeline.util.UtilHelper.*;

import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.Observation;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationKey;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationReporting;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationTransformed;
import gov.cdc.nbs.report.pipeline.observation.repository.ObservationRepository;
import gov.cdc.nbs.report.pipeline.observation.transformer.ProcessObservationDataUtil;
import gov.cdc.nbs.report.pipeline.util.DataProcessingException;
import gov.cdc.nbs.report.pipeline.util.NoDataException;
import gov.cdc.nbs.report.pipeline.util.json.CustomJsonGeneratorImpl;
import gov.cdc.nbs.report.pipeline.util.metrics.CustomMetrics;
import io.micrometer.core.instrument.Counter;
import jakarta.annotation.PostConstruct;
import jakarta.persistence.EntityNotFoundException;
import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;
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
 *   <li>Pushing transformed data to corresponding output topics in Kafka.
 *   <li>Handling retries and dead-letter topics (DLT) for resilient processing.
 * </ul>
 */
@Service
@Setter
@RequiredArgsConstructor
public class ObservationService {
  private static final Logger logger = LoggerFactory.getLogger(ObservationService.class);
  private static final String BEFORE_PATH = "before";

  @Value("${spring.kafka.topics.nbs.observation}")
  private String observationTopic;

  @Value("${spring.kafka.topics.nbs.act-relationship}")
  private String actRelationshipTopic;

  @Value("${spring.kafka.topics.nrt.observation}")
  private String observationTopicOutputReporting;

  @Value("${featureFlag.thread-pool-size:1}")
  private int threadPoolSize;

  private final ObservationRepository observationRepository;

  @Qualifier("observationKafkaTemplate")
  private final KafkaTemplate<String, String> kafkaTemplate;

  private final ProcessObservationDataUtil processObservationDataUtil;
  private final ModelMapper modelMapper = new ModelMapper();
  private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

  private ExecutorService obsExecutor;

  private static String topicDebugLog = "Received Observation with id: {} from topic: {}";
  public static final ToLongFunction<ConsumerRecord<String, String>> toBatchId =
      rec -> rec.timestamp() + rec.offset() + rec.partition();

  private static final String SERVICE_NAME = "observation-reporting";

  private final CustomMetrics metrics;

  private Counter msgProcessed;
  private Counter msgSuccess;
  private Counter msgFailure;

  @PostConstruct
  void initMetrics() {
    String[] tags = {"service", SERVICE_NAME};

    msgProcessed = metrics.counter("obs_msg_processed", tags);
    msgSuccess = metrics.counter("obs_msg_success", tags);
    msgFailure = metrics.counter("obs_msg_failure", tags);

    obsExecutor =
        Executors.newFixedThreadPool(threadPoolSize, new CustomizableThreadFactory("obs-"));
  }

  // BATCHING SPIKE: the per-record @RetryableTopic listener is replaced by a
  // batch listener that groups each poll's observation uids into ONE
  // sp_Observation_Event call. Retry/DLT and missing-entity semantics are
  // intentionally absent — measurement only.
  @KafkaListener(
      topics = {
        "${spring.kafka.topics.nbs.observation}",
        "${spring.kafka.topics.nbs.act-relationship}"
      },
      containerFactory = "observationKafkaListenerContainerFactory")
  public void processMessages(List<ConsumerRecord<String, String>> records) throws Exception {
    if (records.isEmpty()) {
      return;
    }
    long batchId = toBatchId.applyAsLong(records.get(0));
    List<String> observationUids = new ArrayList<>();
    for (ConsumerRecord<String, String> rec : records) {
      if (rec.topic().equals(observationTopic)) {
        observationUids.add(extractUid(rec.value(), "observation_uid"));
      } else if (rec.topic().equals(actRelationshipTopic) && rec.value() != null) {
        processActRelationship(rec.value(), batchId); // low volume; per-record is fine
      }
    }
    logger.info("Batch: {} records -> {} observations", records.size(), observationUids.size());
    if (!observationUids.isEmpty()) {
      processObservationUids(String.join(",", observationUids), batchId);
    }
  }

  // BATCHING SPIKE: one proc call for a comma-separated uid list; each result
  // row is transformed and published exactly as the per-record path did.
  private void processObservationUids(String observationUids, long batchId) {
    metrics.recordTime(
        "obs_msg_processing_seconds",
        () -> {
          try {
            List<Observation> observations =
                observationRepository.computeObservations(observationUids);
            for (Observation observation : observations) {
              msgProcessed.increment();
              ObservationKey observationKey = new ObservationKey();
              observationKey.setObservationUid(observation.getObservationUid());
              ObservationReporting reportingModel =
                  modelMapper.map(observation, ObservationReporting.class);
              ObservationTransformed observationTransformed =
                  processObservationDataUtil.transformObservationData(observation, batchId);
              modelMapper.map(observationTransformed, reportingModel);
              pushKeyValuePairToKafka(
                  observationKey, reportingModel, observationTopicOutputReporting);
              msgSuccess.increment();
            }
          } catch (Exception e) {
            msgFailure.increment();
            throw new DataProcessingException(errorMessage("Observation", observationUids, e), e);
          }
        },
        "service",
        SERVICE_NAME);
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
      } else {
        return;
      }

      logger.info(topicDebugLog, "Act_relationship", sourceActUid, actRelationshipTopic);
      // For LabReport values, we only need to trigger if the relationship is deleted (not covered
      // in updates to Observation)
      // PHC targets are excluded from the LabReport association updates, as the LabReport will
      // receive
      // an update in Observation
      if (typeCd.equals("LabReport") && targetClassCd.equals("OBS")) {
        processObservationUids(sourceActUid, batchId);
      }
    } catch (Exception e) {
      throw new DataProcessingException(errorMessage("ActRelationship", sourceActUid, e), e);
    }
  }

  // This same method can be used for elastic search as well and that is why the generic model is
  // present
  private void pushKeyValuePairToKafka(
      ObservationKey observationKey, Object model, String topicName) {
    String jsonKey = jsonGenerator.generateStringJson(observationKey);
    String jsonValue = jsonGenerator.generateStringJson(model);
    kafkaTemplate.send(topicName, jsonKey, jsonValue);
  }
}
