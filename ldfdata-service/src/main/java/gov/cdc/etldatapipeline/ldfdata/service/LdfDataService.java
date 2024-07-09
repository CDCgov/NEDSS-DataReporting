package gov.cdc.etldatapipeline.ldfdata.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.ldfdata.model.dto.LdfData;
import gov.cdc.etldatapipeline.ldfdata.model.dto.LdfDataKey;
import gov.cdc.etldatapipeline.ldfdata.repository.LdfDataRepository;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.kstream.Consumed;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@Setter
@RequiredArgsConstructor
public class LdfDataService {
    private static final Logger logger = LoggerFactory.getLogger(LdfDataService.class);

    @Value("${spring.kafka.stream.input.ldfdata.topic-name}")
    private String ldfDataTopic;

    @Value("${spring.kafka.stream.output.ldfdata.topic-name-reporting}")
    public String ldfDataTopicReporting;

    private final LdfDataRepository ldfDataRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    LdfDataKey ldfDataKey = new LdfDataKey();
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    private String topicDebugLog = "Received business_object_nm={},ldf_uid={},business_object_uid={} from topic: {}";

    @Autowired
    public void processMessage(StreamsBuilder streamsBuilder) {
        streamsBuilder.stream(ldfDataTopic, Consumed.with(Serdes.String(), Serdes.String()))
                .filter((k, v) -> v != null)
                .mapValues((key, value) -> processLdfData(value))
                .filter((key, value) -> value != null)
                .peek((key, value) -> logger.info("Received LDF data: {}", value));
    }

    public String processLdfData(String value) {
        String busObjNm = "";
        String ldfUid = "";
        String busObjUid = "";
        try {
            ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
            JsonNode jsonNode = objectMapper.readTree(value);
            JsonNode payloadNode = jsonNode.get("payload").path("after");
            if (payloadNode != null
                    && payloadNode.has("business_object_nm")
                    && payloadNode.has("ldf_uid")
                    && payloadNode.has("business_object_uid")) {
                busObjNm = payloadNode.get("business_object_nm").asText();
                ldfUid = payloadNode.get("ldf_uid").asText();
                busObjUid = payloadNode.get("business_object_uid").asText();

                logger.debug(topicDebugLog, busObjNm, ldfUid, busObjUid, ldfDataTopic);
                Optional<LdfData> ldfData = ldfDataRepository.computeLdfData(busObjNm, ldfUid, busObjUid);
                if (ldfData.isPresent()) {
                    ldfDataKey.setLdfUid(Long.valueOf(ldfUid));
                    ldfDataKey.setBusinessObjectUid(Long.valueOf(busObjUid));
                    pushKeyValuePairToKafka(ldfDataKey, ldfData.get(), ldfDataTopicReporting);
                    return objectMapper.writeValueAsString(ldfData.get());
                }
            }
        } catch (Exception e) {
            String msg = "Error processing LDF data" + (
                    !busObjNm.isEmpty() ?
                            " for business_object_nm='" + busObjNm +
                            "',ldf_uid='" + ldfUid +
                            "',business_object_uid='" + busObjUid +"': {}"
                            : ": {}"
            );
            logger.error(msg, e.getMessage());
        }
        return null;
    }

    private void pushKeyValuePairToKafka(LdfDataKey ldfDataKey, Object model, String topicName) {
        String jsonKey = jsonGenerator.generateStringJson(ldfDataKey);
        String jsonValue = jsonGenerator.generateStringJson(model);
        kafkaTemplate.send(topicName, jsonKey, jsonValue);
    }
}
