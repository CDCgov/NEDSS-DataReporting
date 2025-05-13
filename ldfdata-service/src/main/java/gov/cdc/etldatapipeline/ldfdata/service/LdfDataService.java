package gov.cdc.etldatapipeline.ldfdata.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.DataProcessingException;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.ldfdata.model.dto.LdfData;
import gov.cdc.etldatapipeline.ldfdata.model.dto.LdfDataKey;
import gov.cdc.etldatapipeline.ldfdata.repository.LdfDataRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.errors.SerializationException;
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
import org.springframework.stereotype.Service;

import java.util.NoSuchElementException;
import java.util.Optional;
import static gov.cdc.etldatapipeline.commonutil.UtilHelper.extractChangeDataCaptureOperation;

@Service
@Setter
@RequiredArgsConstructor
public class LdfDataService {
    private static final Logger logger = LoggerFactory.getLogger(LdfDataService.class);
    private static final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    @Value("${spring.kafka.input.topic-name}")
    private String ldfDataTopic;

    @Value("${spring.kafka.output.topic-name-reporting}")
    public String ldfDataTopicReporting;

    private final LdfDataRepository ldfDataRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    LdfDataKey ldfDataKey = new LdfDataKey();
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    private String topicDebugLog = "Received business_object_nm={},ldf_uid={},business_object_uid={} from topic: {}";

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
            topics = "${spring.kafka.input.topic-name}"
    )
    public void processMessage(ConsumerRecord<String, String> rec,
                               Consumer<?,?> consumer) {
        String topic = rec.topic();
        String message = rec.value();
        logger.debug(topicDebugLog, message, topic);
        if (message == null || message.isBlank()) {
            logger.warn("Received null or empty message on topic: {}", topic);
        } else {
            processLdfData(message);
        }
        consumer.commitSync();
    }

    public void processLdfData(String value) {
        String busObjNm = "";
        String ldfUid = "";
        String busObjUid = "";
        try {
            JsonNode jsonNode = objectMapper.readTree(value);
            String operationType = extractChangeDataCaptureOperation(value);
            String payloadString = "payload";
            JsonNode payloadNode = operationType.equals("d")? jsonNode.get(payloadString).path("before"): jsonNode.get(payloadString).path("after");
            ldfUid = extractUid(payloadNode);
            busObjNm = payloadNode.get("business_object_nm").asText();
            busObjUid = payloadNode.get("business_object_uid").asText();
            
            Optional<LdfData> ldfData;

            logger.info(topicDebugLog, busObjNm, ldfUid, busObjUid, ldfDataTopic);

            if (operationType.equals("d")){
                LdfData custLdfData = initializeBean(ldfUid, busObjUid, busObjNm);
                ldfDataKey.setLdfUid(Long.valueOf(ldfUid));
                ldfData =  Optional.of(custLdfData);
                pushKeyValuePairToKafka(ldfDataKey, ldfData.get(), ldfDataTopicReporting);
                logger.info("LDF data (uid={}) sent to {}", ldfUid, ldfDataTopicReporting);

            } else {
                
                ldfData = ldfDataRepository.computeLdfData(busObjNm, ldfUid, busObjUid);
                if (ldfData.isPresent()) {
                    ldfDataKey.setLdfUid(Long.valueOf(ldfUid));
                    pushKeyValuePairToKafka(ldfDataKey, ldfData.get(), ldfDataTopicReporting);
                    logger.info("LDF data (uid={}) sent to {}", ldfUid, ldfDataTopicReporting);
                }
                else {
                    throw new EntityNotFoundException("Unable to find LDF data with id: " + ldfUid);
                }
            }
        } catch (EntityNotFoundException ex) {
            throw new NoDataException(ex.getMessage(), ex);
        } catch (Exception e) {
            String msg = "Error processing LDF data" + (busObjNm.isEmpty() ? ": " :
                    " for business_object_nm='" + busObjNm +
                    "',ldf_uid='" + ldfUid +
                    "',business_object_uid='" + busObjUid +"': "
            ) + e.getMessage();
            throw new DataProcessingException(msg, e);
        }
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
        try {
            if (!payloadNode.isMissingNode()
                    && payloadNode.has("business_object_nm")
                    && payloadNode.has("ldf_uid")
                    && payloadNode.has("business_object_uid")) {
                return payloadNode.get("ldf_uid").asText();

            } else {
                throw new NoSuchElementException("The LDF data is missing in the message payload.");
            }
        } catch (Exception ex) {
            logger.error("JsonProcessingException: ", ex);
            throw new NoSuchElementException("The LDF data is missing in the message payload.");
        }
    }
}
