package gov.cdc.nbs.report.pipeline.ldfdata.service;

import static gov.cdc.nbs.report.pipeline.util.UtilHelper.extractChangeDataCaptureOperation;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.nbs.report.pipeline.ldfdata.model.dto.LdfData;
import gov.cdc.nbs.report.pipeline.ldfdata.model.dto.LdfDataKey;
import gov.cdc.nbs.report.pipeline.ldfdata.repository.LdfDataRepository;
import gov.cdc.nbs.report.pipeline.util.DataProcessingException;
import gov.cdc.nbs.report.pipeline.util.NoDataException;
import gov.cdc.nbs.report.pipeline.util.json.CustomJsonGeneratorImpl;
import gov.cdc.nbs.report.pipeline.util.metrics.CustomMetrics;
import io.micrometer.core.instrument.Counter;
import jakarta.annotation.PostConstruct;
import jakarta.persistence.EntityNotFoundException;
import java.util.NoSuchElementException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.Map;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.errors.SerializationException;
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

@Service
@Setter
@RequiredArgsConstructor
public class LdfDataService {
  private static final Logger logger = LoggerFactory.getLogger(LdfDataService.class);
  private static final ObjectMapper objectMapper =
      new ObjectMapper().registerModule(new JavaTimeModule());
  private ExecutorService ldfExecutor;

  @Value("${spring.kafka.topics.nbs.state-defined-field-data}")
  private String ldfDataTopic;

  @Value("${spring.kafka.topics.nrt.ldf-data}")
  public String ldfDataTopicReporting;

  @Value("${featureFlag.thread-pool-size:1}")
  private int threadPoolSize;

  private final LdfDataRepository ldfDataRepository;

  @Qualifier("ldfdataKafkaTemplate")
  private final KafkaTemplate<String, String> kafkaTemplate;

  LdfDataKey ldfDataKey = new LdfDataKey();
  private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

  private String topicDebugLog =
      "Received business_object_nm={},ldf_uid={},business_object_uid={} from topic: {}";

  private static final String SERVICE_NAME = "ldfdata-reporting";
  private static final String SERVICE_TAG = "service";

  private final CustomMetrics metrics;

  private Counter msgProcessed;
  private Counter msgSuccess;
  private Counter msgFailure;

  @PostConstruct
  void initMetrics() {
    String[] tags = {SERVICE_TAG, SERVICE_NAME};

    msgProcessed = metrics.counter("ldf_msg_processed", tags);
    msgSuccess = metrics.counter("ldf_msg_success", tags);
    msgFailure = metrics.counter("ldf_msg_failure", tags);

    ldfExecutor =
        Executors.newFixedThreadPool(threadPoolSize, new CustomizableThreadFactory("ldf-"));
  }

  // BATCHING SPIKE: records grouped by business_object_nm only — BOTH proc
  // parameters are IN-style lists (@ldf_uid_list, @bus_obj_uid_list), so one
  // call per object type covers the poll. The cross-product only returns
  // rows that exist, which during a snapshot is the poll's own records (a
  // few boundary rows publish twice; the sink upserts, so it is harmless).
  // Deletes stay per-record (rare; they publish a tombstone bean, no proc).
  // Retry/DLT and missing-entity semantics intentionally absent.
  @KafkaListener(
      topics = "${spring.kafka.topics.nbs.state-defined-field-data}",
      containerFactory = "ldfdataKafkaListenerContainerFactory")
  public void processMessages(List<ConsumerRecord<String, String>> records) throws Exception {
    Map<String, Set<String>> ldfUidsByObj = new LinkedHashMap<>();
    Map<String, Set<String>> busObjUidsByObj = new LinkedHashMap<>();
    for (ConsumerRecord<String, String> rec : records) {
      String message = rec.value();
      if (message == null || message.isBlank()) {
        logger.warn("Received null or empty message on topic: {}", rec.topic());
        continue;
      }
      msgProcessed.increment();
      JsonNode jsonNode = objectMapper.readTree(message).get("payload");
      String operationType = extractChangeDataCaptureOperation(message);
      JsonNode payloadNode =
          operationType.equals("d") ? jsonNode.path("before") : jsonNode.path("after");
      payloadNode = payloadNode.isMissingNode() ? jsonNode : payloadNode;
      String ldfUid = extractUid(payloadNode);
      String busObjNm = payloadNode.get("business_object_nm").asText();
      String busObjUid = payloadNode.get("business_object_uid").asText();
      if (operationType.equals("d")) {
        publishLdfData(initializeBean(ldfUid, busObjUid, busObjNm));
      } else {
        ldfUidsByObj.computeIfAbsent(busObjNm, k -> new LinkedHashSet<>()).add(ldfUid);
        busObjUidsByObj.computeIfAbsent(busObjNm, k -> new LinkedHashSet<>()).add(busObjUid);
      }
    }
    logger.info(
        "Batch: {} records -> {} business-object groups", records.size(), ldfUidsByObj.size());
    for (Map.Entry<String, Set<String>> entry : ldfUidsByObj.entrySet()) {
      processLdfDataUids(
          entry.getKey(),
          String.join(",", entry.getValue()),
          String.join(",", busObjUidsByObj.get(entry.getKey())));
    }
  }

  private void processLdfDataUids(String busObjNm, String ldfUid, String busObjUids) {
    metrics.recordTime(
        "ldf_msg_processing_seconds",
        () -> {
          try {
            List<LdfData> results = ldfDataRepository.computeLdfData(busObjNm, ldfUid, busObjUids);
            for (LdfData ldfData : results) {
              publishLdfData(ldfData);
            }
          } catch (Exception e) {
            msgFailure.increment();
            throw new DataProcessingException(
                "Error processing LDF data for business_object_nm='" + busObjNm
                    + "',ldf_uid='" + ldfUid + "',business_object_uid(s)='" + busObjUids + "'",
                e);
          }
        },
        SERVICE_TAG,
        SERVICE_NAME);
  }

  private void publishLdfData(LdfData ldfData) {
    LdfDataKey key = new LdfDataKey();
    key.setLdfUid(ldfData.getLdfUid());
    key.setBusObjUid(ldfData.getBusinessObjectUid());
    pushKeyValuePairToKafka(key, ldfData, ldfDataTopicReporting);
    msgSuccess.increment();
  }



  private LdfData initializeBean(String ldfUid, String busObjUid, String busObjNm) {

    LdfData ldfData = new LdfData();
    ldfData.setBusinessObjectUid(Long.valueOf(busObjUid));
    ldfData.setLdfUid(Long.valueOf(ldfUid));
    ldfData.setLdfFieldDataBusinessObjectNm(busObjNm);
    return ldfData;
  }

  private void pushKeyValuePairToKafka(LdfDataKey ldfDataKey, Object model, String topicName) {
    String jsonKey = jsonGenerator.generateStringJson(ldfDataKey);
    String jsonValue = jsonGenerator.generateStringJson(model);
    kafkaTemplate.send(topicName, jsonKey, jsonValue);
  }

  private String extractUid(JsonNode payloadNode) {

    if (!payloadNode.isMissingNode()
        && payloadNode.has("business_object_nm")
        && payloadNode.has("ldf_uid")
        && payloadNode.has("business_object_uid")) {
      return payloadNode.get("ldf_uid").asText();

    } else {
      throw new NoSuchElementException("The LDF data is missing in the message payload.");
    }
  }
}
