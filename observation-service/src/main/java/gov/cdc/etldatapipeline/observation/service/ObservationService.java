package gov.cdc.etldatapipeline.observation.service;


import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.observation.repository.IObservationRepository;
import gov.cdc.etldatapipeline.observation.repository.model.dto.Observation;
import gov.cdc.etldatapipeline.observation.repository.model.reporting.ObservationKey;
import gov.cdc.etldatapipeline.observation.repository.model.dto.ObservationTransformed;
import gov.cdc.etldatapipeline.observation.repository.model.reporting.ObservationReporting;
import gov.cdc.etldatapipeline.observation.util.ProcessObservationDataUtil;
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
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.function.ToLongFunction;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.errorMessage;
import static gov.cdc.etldatapipeline.commonutil.UtilHelper.extractUid;

@Service
@Setter
@RequiredArgsConstructor
public class ObservationService {
    private static final Logger logger = LoggerFactory.getLogger(ObservationService.class);

    @Value("${spring.kafka.input.topic-name}")
    private String observationTopic;

    @Value("${spring.kafka.output.topic-name-reporting}")
    private String observationTopicOutputReporting;

    private final IObservationRepository iObservationRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ProcessObservationDataUtil processObservationDataUtil;
    private final ModelMapper modelMapper = new ModelMapper();
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    private static String topicDebugLog = "Received Observation with id: {} from topic: {}";
    public static final ToLongFunction<ConsumerRecord<String, String>> toBatchId = rec -> rec.timestamp()+rec.offset()+rec.partition();

    ObservationKey observationKey = new ObservationKey();

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
    public void processMessage(ConsumerRecord<String, String> rec) {
        logger.debug(topicDebugLog, rec.value(), rec.topic());
        long batchId = toBatchId.applyAsLong(rec);
        processObservation(rec.value(), batchId);
    }

    private void processObservation(String value, long batchId) {
        String observationUid = "";
        try {
            observationUid = extractUid(value,"observation_uid");
            observationKey.setObservationUid(Long.valueOf(observationUid));
            logger.info(topicDebugLog, observationUid, observationTopic);
            Optional<Observation> observationData = iObservationRepository.computeObservations(observationUid);
            if(observationData.isPresent()) {
                ObservationReporting reportingModel = modelMapper.map(observationData.get(), ObservationReporting.class);
                ObservationTransformed observationTransformed = processObservationDataUtil.transformObservationData(observationData.get(), batchId);
                modelMapper.map(observationTransformed, reportingModel);
                pushKeyValuePairToKafka(observationKey, reportingModel, observationTopicOutputReporting);
                logger.info("Observation data (uid={}) sent to {}", observationUid, observationTopicOutputReporting);
            }
            else {
                throw new EntityNotFoundException("Unable to find Observation with id: " + observationUid);
            }
        } catch (EntityNotFoundException ex) {
            throw new NoDataException(ex.getMessage(), ex);
        } catch (Exception e) {
            throw new RuntimeException(errorMessage("Observation", observationUid, e), e);
        }
    }

    // This same method can be used for elastic search as well and that is why the generic model is present
    private void pushKeyValuePairToKafka(ObservationKey observationKey, Object model, String topicName) {
        String jsonKey = jsonGenerator.generateStringJson(observationKey);
        String jsonValue = jsonGenerator.generateStringJson(model);
        kafkaTemplate.send(topicName, jsonKey, jsonValue);
    }
}
