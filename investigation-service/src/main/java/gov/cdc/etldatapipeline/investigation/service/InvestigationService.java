package gov.cdc.etldatapipeline.investigation.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.investigation.repository.odse.InvestigationRepository;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.Investigation;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.InvestigationKey;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.InvestigationTransformed;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InvestigationReporting;
import gov.cdc.etldatapipeline.investigation.util.ProcessInvestigationDataUtil;
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
public class InvestigationService {
    private static final Logger logger = LoggerFactory.getLogger(InvestigationService.class);

    @Value("${spring.kafka.input.topic-name}")
    private String investigationTopic;

    @Value("${spring.kafka.output.topic-name-reporting}")
    public String investigationTopicReporting;

    private final InvestigationRepository investigationRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ProcessInvestigationDataUtil processDataUtil;
    InvestigationKey investigationKey = new InvestigationKey();
    private final ModelMapper modelMapper = new ModelMapper();
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    private String topicDebugLog = "Received Investigation ID: {} from topic: {}";

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
        processInvestigation(message);
    }

    public String processInvestigation(String value) {
        String publicHealthCaseUid = "";
        try {
            ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
            JsonNode jsonNode = objectMapper.readTree(value);
            JsonNode payloadNode = jsonNode.get("payload").path("after");
            if (payloadNode != null && payloadNode.has("public_health_case_uid")) {
                publicHealthCaseUid = payloadNode.get("public_health_case_uid").asText();
                investigationKey.setPublicHealthCaseUid(Long.valueOf(publicHealthCaseUid));

                // Calling sp_public_health_case_fact_datamart_event
                logger.info("Executing stored proc with ids: {} to populate PHС fact datamart", publicHealthCaseUid);
                investigationRepository.populatePhcFact(publicHealthCaseUid);
                logger.info("Stored proc executed");

                logger.debug(topicDebugLog, publicHealthCaseUid, investigationTopic);
                Optional<Investigation> investigationData = investigationRepository.computeInvestigations(publicHealthCaseUid);
                if (investigationData.isPresent()) {
                    InvestigationReporting reportingModel = modelMapper.map(investigationData.get(), InvestigationReporting.class);
                    InvestigationTransformed investigationTransformed = processDataUtil.transformInvestigationData(investigationData.get());
                    buildReportingModelForTransformedData(reportingModel, investigationTransformed);
                    pushKeyValuePairToKafka(investigationKey, reportingModel, investigationTopicReporting);
                    processDataUtil.processNotifications(investigationData.get().getInvestigationNotifications(), objectMapper);
                    return objectMapper.writeValueAsString(investigationData.get());
                } else {
                    throw new NoDataException("No investigation data found for id: " + publicHealthCaseUid);
                }
            }
        } catch (NoDataException nde) {
            logger.error(nde.getMessage());
            throw nde;
        } catch (Exception e) {
            String msg = "Error processing investigation" +
                    (!publicHealthCaseUid.isEmpty() ? " for ids='" + publicHealthCaseUid + "': {}" : ": {}");
            logger.error(msg, e.getMessage());
            throw new RuntimeException(e);
        }
        return null;
    }

    // This same method can be used for elastic search as well and that is why the generic model is present
    private void pushKeyValuePairToKafka(InvestigationKey investigationKey, Object model, String topicName) {
        String jsonKey = jsonGenerator.generateStringJson(investigationKey);
        String jsonValue = jsonGenerator.generateStringJson(model);
        kafkaTemplate.send(topicName, jsonKey, jsonValue);
    }

    private void buildReportingModelForTransformedData(InvestigationReporting reportingModel, InvestigationTransformed investigationTransformed) {
        reportingModel.setInvestigatorId(investigationTransformed.getInvestigatorId());
        reportingModel.setPhysicianId(investigationTransformed.getPhysicianId());
        reportingModel.setPatientId(investigationTransformed.getPatientId());
        reportingModel.setOrganizationId(investigationTransformed.getOrganizationId());
        reportingModel.setInvStateCaseId(investigationTransformed.getInvStateCaseId());
        reportingModel.setCityCountyCaseNbr(investigationTransformed.getCityCountyCaseNbr());
        reportingModel.setLegacyCaseId(investigationTransformed.getLegacyCaseId());
        reportingModel.setPhcInvFormId(investigationTransformed.getPhcInvFormId());
        reportingModel.setRdbTableNameList(investigationTransformed.getRdbTableNameList());
    }
}
