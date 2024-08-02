package gov.cdc.etldatapipeline.observation.service;


import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.observation.repository.IObservationRepository;
import gov.cdc.etldatapipeline.observation.repository.model.dto.Observation;
import gov.cdc.etldatapipeline.observation.repository.model.dto.ObservationKey;
import gov.cdc.etldatapipeline.observation.repository.model.dto.ObservationTransformed;
import gov.cdc.etldatapipeline.observation.repository.model.reporting.ObservationReporting;
import gov.cdc.etldatapipeline.observation.util.ProcessObservationDataUtil;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
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
import org.springframework.kafka.support.serializer.DeserializationException;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.retry.annotation.Backoff;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@Setter
@RequiredArgsConstructor
public class ObservationService {
    private static final Logger logger = LoggerFactory.getLogger(ObservationService.class);

    @Value("${spring.kafka.input.topic-name}")
    private String observationTopic;

    @Value("${spring.kafka.output.topic-name-reporting}")
    public String observationTopicOutputReporting;

    @Value("${spring.kafka.output.topic-name-es}")
    public String observationTopicOutputElasticSearch;

    @Value("${spring.kafka.dlq.topic-name-dlq}")
    public String observationTopicOutputDlq;


    private final IObservationRepository iObservationRepository;
    private String topicDebugLog = "Received Observation ID: {} from topic: {}";
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ProcessObservationDataUtil processObservationDataUtil;
    ObservationKey observationKey = new ObservationKey();
    private final ModelMapper modelMapper = new ModelMapper();
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();


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
    public void processMessage(String message,
                               @Header(KafkaHeaders.RECEIVED_TOPIC) String topic) {
        logger.debug(topicDebugLog, message, topic);
        processObservation(message);
    }

    private String processObservation(String value) {
        try {
            ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
            JsonNode jsonNode = objectMapper.readTree(value);
            JsonNode payloadNode = jsonNode.get("payload").path("after");
            if (payloadNode != null && payloadNode.has("observation_uid")) {
                String observationUid = payloadNode.get("observation_uid").asText();
                observationKey.setObservationUid(Long.valueOf(observationUid));
                logger.debug(topicDebugLog, observationUid, observationTopic);
                Optional<Observation> observationData = iObservationRepository.computeObservations(observationUid);
                if(observationData.isPresent()) {
                    ObservationReporting reportingModel = modelMapper.map(observationData.get(), ObservationReporting.class);
                    ObservationTransformed observationTransformed = processObservationDataUtil.transformObservationData(observationData.get());
                    buildReportingModelForTransformedData(reportingModel, observationTransformed);
                    pushKeyValuePairToKafka(observationKey, reportingModel, observationTopicOutputReporting);
                    return objectMapper.writeValueAsString(observationData.get());
                }
                else {
                    throw new NoDataException("No observation data found for id: " + observationUid);
                }
            }
            else {
                logger.info("No observation id to process.");
            }
        } catch (NoDataException nde) {
            logger.error(nde.getMessage());
            throw nde;
        } catch (Exception e) {
            logger.error("Error processing observation: {}", e.getMessage());
            throw new RuntimeException(e);
        }
        return null;
    }

    // This same method can be used for elastic search as well and that is why the generic model is present
    private void pushKeyValuePairToKafka(ObservationKey observationKey, Object model, String topicName) {
        String jsonKey = jsonGenerator.generateStringJson(observationKey);
        String jsonValue = jsonGenerator.generateStringJson(model);
        kafkaTemplate.send(topicName, jsonKey, jsonValue);
    }

    protected void buildReportingModelForTransformedData(ObservationReporting reportingModel, ObservationTransformed observationTransformed) {
        reportingModel.setOrderingPersonId(observationTransformed.getOrderingPersonId());
        reportingModel.setPatientId(observationTransformed.getPatientId());
        reportingModel.setPerformingOrganizationId(observationTransformed.getPerformingOrganizationId());
        reportingModel.setAuthorOrganizationId(observationTransformed.getAuthorOrganizationId());
        reportingModel.setOrderingOrganizationId(observationTransformed.getOrderingOrganizationId());
        reportingModel.setMaterialId(observationTransformed.getMaterialId());
        reportingModel.setResultObservationUid(observationTransformed.getResultObservationUid());
    }
}
