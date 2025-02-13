package gov.cdc.etldatapipeline.postprocessingservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.postprocessingservice.repository.*;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.DatamartData;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto.Datamart;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import org.apache.kafka.common.errors.SerializationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.RetryableTopic;
import org.springframework.kafka.retrytopic.DltStrategy;
import org.springframework.kafka.retrytopic.TopicSuffixingStrategy;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.kafka.support.serializer.DeserializationException;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.retry.annotation.Backoff;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.*;
import java.util.Map.Entry;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.function.BiConsumer;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static gov.cdc.etldatapipeline.postprocessingservice.service.Entity.*;

@Service
@RequiredArgsConstructor
@EnableScheduling
public class PostProcessingService {
    private static final Logger logger = LoggerFactory.getLogger(PostProcessingService.class);
    final Map<String, Queue<Long>> idCache = new ConcurrentHashMap<>();
    final Map<Long, String> idVals = new ConcurrentHashMap<>();
    final Map<String, Set<Map<Long, Long>>> dmCache = new ConcurrentHashMap<>();

    private final PostProcRepository postProcRepository;
    private final InvestigationRepository investigationRepository;

    private final ProcessDatamartData datamartProcessor;

    static final String PAYLOAD = "payload";
    static final String SP_EXECUTION_COMPLETED = "Stored proc execution completed: {}";
    static final String PROCESSING_MESSAGE_TOPIC_LOG_MSG = "Processing {} message topic. Calling stored proc: {} '{}'";

    static final String MORB_REPORT = "MorbReport";
    static final String LAB_REPORT = "LabReport";
    static final String LAB_REPORT_MORB = "LabReportMorb";

    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
    private final Object cacheLock = new Object();

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
                    RuntimeException.class
            }
    )
    @KafkaListener(topics = {
            "${spring.kafka.topic.investigation}",
            "${spring.kafka.topic.organization}",
            "${spring.kafka.topic.patient}",
            "${spring.kafka.topic.provider}",
            "${spring.kafka.topic.notification}",
            "${spring.kafka.topic.case_management}",
            "${spring.kafka.topic.interview}",
            "${spring.kafka.topic.ldf_data}",
            "${spring.kafka.topic.observation}",
            "${spring.kafka.topic.place}",
            "${spring.kafka.topic.user_profile}",
            "${spring.kafka.topic.contact_record}"
    })
    public void postProcessMessage(
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_KEY) String key,
            @Payload String payload) {

        Long id = extractIdFromMessage(topic, key);
        idCache.computeIfAbsent(topic, k -> new ConcurrentLinkedQueue<>()).add(id);
        Optional<String> val = Optional.ofNullable(extractValFromMessage(topic, payload));
        val.ifPresent(v -> idVals.put(id, v));
    }

    private Long extractIdFromMessage(String topic, String messageKey) {
        try {
            logger.info("Got this key payload: {} from the topic: {}", messageKey, topic);
            JsonNode keyNode = objectMapper.readTree(messageKey);

            Entity entity = getEntityByTopic(topic);
            if (Objects.isNull(keyNode.get(PAYLOAD).get(entity.getUidName()))) {
                throw new NoSuchElementException("The '" + entity.getUidName() + "' value is missing in the '" + topic + "' message payload.");
            }
            return keyNode.get(PAYLOAD).get(entity.getUidName()).asLong();
        } catch (Exception e) {
            String msg = "Error processing '" + topic + "'  message: " + e.getMessage();
            throw new RuntimeException(msg, e);
        }
    }

    @RetryableTopic(
            attempts = "${spring.kafka.consumer.max-retry}",
            autoCreateTopics = "false",
            dltStrategy = DltStrategy.FAIL_ON_ERROR,
            retryTopicSuffix = "${spring.kafka.dlq.retry-suffix}",
            dltTopicSuffix = "${spring.kafka.dlq.dlq-suffix}",
            topicSuffixingStrategy = TopicSuffixingStrategy.SUFFIX_WITH_INDEX_VALUE,
            backoff = @Backoff(delay = 1000, multiplier = 2.0),
            exclude = {
                    SerializationException.class,
                    DeserializationException.class,
                    RuntimeException.class
            }
    )
    @KafkaListener(topics = {"${spring.kafka.topic.datamart}"})
    public void postProcessDatamart(
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Payload String payload) {
        try {
            logger.info("Got this payload: {} from the topic: {}", payload, topic);
            JsonNode payloadNode = objectMapper.readTree(payload);

            Datamart dmData = objectMapper.readValue(payloadNode.get(PAYLOAD).toString(), Datamart.class);
            if (Objects.isNull(dmData)) {
                logger.info("For payload: {} DataMart object is null. Skipping further processing", payloadNode);
                return;
            }
            if (Objects.isNull(dmData.getPublicHealthCaseUid()) || Objects.isNull(dmData.getPatientUid())) {
                logger.info("For payload: {} DataMart Public Health Case/Patient Id is null. Skipping further processing", payloadNode);
                return;
            }
            if (Objects.isNull(dmData.getDatamart())) {
                logger.info("For payload: {} DataMart value is null. Skipping further processing", payloadNode);
                return;
            }
            Map<Long, Long> dmMap = new HashMap<>();
            dmMap.put(dmData.getPublicHealthCaseUid(), dmData.getPatientUid());
            dmCache.computeIfAbsent(dmData.getDatamart(), k -> ConcurrentHashMap.newKeySet()).add(dmMap);
        } catch (Exception e) {
            String msg = "Error processing datamart message: " + e.getMessage();
            throw new RuntimeException(msg, e);
        }
    }

    @Scheduled(fixedDelayString = "${service.fixed-delay.cached-ids}")
    protected void processCachedIds() {

        // Making cache snapshot preventing out-of-sequence ids processing
        final Map<String, List<Long>> idCacheSnapshot;
        final Map<Long, String> idValsSnapshot;
        synchronized (cacheLock) {
            idCacheSnapshot = idCache.entrySet().stream()
                    .collect(Collectors.toMap(Map.Entry::getKey, entry -> new ArrayList<>(entry.getValue())));
            idCache.clear();

            idValsSnapshot = idVals.entrySet().stream().collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
            idVals.clear();
        }

        if (!idCacheSnapshot.isEmpty()) {
            List<Entry<String, List<Long>>> sortedEntries = idCacheSnapshot.entrySet().stream()
                    .sorted(Comparator.comparingInt(entry -> getEntityByTopic(entry.getKey()).getPriority())).toList();

            List<DatamartData> dmData = new ArrayList<>();

            List<Long> investigationUids = new ArrayList<>();
            List<Long> observationUids = new ArrayList<>();
            List<Long> notificationUids = new ArrayList<>();
            List<Long> contactRecordUids = new ArrayList<>();

            for (Entry<String, List<Long>> entry : sortedEntries) {
                String keyTopic = entry.getKey();
                List<Long> ids = entry.getValue();

                logger.info("Processing {} id(s) from topic: {}", ids.size(), keyTopic);

                Entity entity = getEntityByTopic(keyTopic);
                switch (entity) {
                    case ORGANIZATION:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForOrganizationIds);
                        break;
                    case PROVIDER:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForProviderIds);
                        break;
                    case PATIENT:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForPatientIds);
                        break;
                    case USER_PROFILE:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForUserProfile);
                        break;
                    case D_PLACE:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForDPlace);
                        break;
                    case INVESTIGATION:
                        dmData = processInvestigation(keyTopic, entity, ids, idValsSnapshot);
                        investigationUids = ids;
                        break;
                    case CONTACT:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForDContactRecord);
                        processTopic(keyTopic, entity.getEntityName(), ids,
                                postProcRepository::executeStoredProcForFContactRecordCase, "sp_f_contact_record_case_postprocessing");
                        contactRecordUids = ids;
                        break;
                    case NOTIFICATION:
                        List<DatamartData> dmDataN = processTopic(keyTopic, entity, ids,
                                investigationRepository::executeStoredProcForNotificationIds);
                        dmData = Stream.concat(dmData.stream(), dmDataN.stream()).distinct().toList();
                        notificationUids = ids;
                        break;
                    case CASE_MANAGEMENT:
                        processTopic(keyTopic, entity, ids, investigationRepository::executeStoredProcForCaseManagement);
                        processTopic(keyTopic, entity.getEntityName(), ids,
                                investigationRepository::executeStoredProcForFStdPageCase, "sp_f_std_page_case_postprocessing");
                        break;
                    case INTERVIEW:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForDInterview);
                        processTopic(keyTopic, entity.getEntityName(), ids,
                                postProcRepository::executeStoredProcForFInterviewCase, "sp_f_interview_case_postprocessing");
                        break;
                    case LDF_DATA:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForLdfIds);
                        break;
                    case OBSERVATION:
                        dmData = processObservation(idValsSnapshot, keyTopic, entity, dmData);
                        observationUids = ids;
                        break;
                    default:
                        logger.warn("Unknown topic: {} cannot be processed", keyTopic);
                        break;
                }
            }
            datamartProcessor.process(dmData);

            processEventMetricDatamart(investigationUids, observationUids, notificationUids, contactRecordUids);
        } else {
            logger.info("No ids to process from the topics.");
        }
    }

    private List<DatamartData> processInvestigation(String keyTopic, Entity entity, List<Long> ids, Map<Long, String> idValsSnapshot) {
        List<DatamartData> dmData;
        dmData = processTopic(keyTopic, entity, ids,
                investigationRepository::executeStoredProcForPublicHealthCaseIds);

        ids.stream().filter(idValsSnapshot::containsKey).forEach(id ->
                processTopic(keyTopic, CASE_ANSWERS, id, idValsSnapshot.get(id),
                        investigationRepository::executeStoredProcForPageBuilder));

        processTopic(keyTopic, F_PAGE_CASE, ids,
                investigationRepository::executeStoredProcForFPageCase);

        processTopic(keyTopic, CASE_COUNT, ids,
                investigationRepository::executeStoredProcForCaseCount);
        return dmData;
    }

    private List<DatamartData> processObservation(Map<Long, String> idValsSnapshot, String keyTopic, Entity entity, List<DatamartData> dmData) {
        final List<Long> morbIds;
        final List<Long> labIds;
        synchronized (cacheLock) {
            morbIds = idValsSnapshot.entrySet().stream()
                    .filter(e -> e.getValue().equals(MORB_REPORT)).map(Entry::getKey).toList();
            labIds = idValsSnapshot.entrySet().stream()
                    .filter(e -> e.getValue().equals(LAB_REPORT)).map(Entry::getKey).toList();
        }

        if (!morbIds.isEmpty()) {
            List<DatamartData> dmDataM = processTopic(keyTopic, entity.getEntityName(), morbIds,
                    postProcRepository::executeStoredProcForMorbReport, "sp_d_morbidity_report_postprocessing");
            dmData = Stream.concat(dmData.stream(), dmDataM.stream()).distinct().toList();
        }

        if (!labIds.isEmpty()) {
            processTopic(keyTopic, entity.getEntityName(), labIds,
                    postProcRepository::executeStoredProcForLabTest, "sp_d_lab_test_postprocessing");

            List<DatamartData> dmDataL = processTopic(keyTopic, entity.getEntityName(), labIds,
                    postProcRepository::executeStoredProcForLabTestResult, "sp_d_labtest_result_postprocessing");
            dmData = Stream.concat(dmData.stream(), dmDataL.stream()).distinct().toList();

            processTopic(keyTopic, entity.getEntityName(), labIds,
                    postProcRepository::executeStoredProcForLab100Datamart, "sp_lab100_datamart_postprocessing");
            processTopic(keyTopic, entity.getEntityName(), labIds,
                    postProcRepository::executeStoredProcForLab101Datamart, "sp_lab101_datamart_postprocessing");
        }
        return dmData;
    }

    @Scheduled(fixedDelayString = "${service.fixed-delay.datamart}")
    protected void processDatamartIds() {
        for (Map.Entry<String, Set<Map<Long, Long>>> entry : dmCache.entrySet()) {
            if (!entry.getValue().isEmpty()) {
                String dmType = entry.getKey();
                Set<Map<Long, Long>> dmSet = entry.getValue();
                dmCache.put(dmType, ConcurrentHashMap.newKeySet());

                String cases = dmSet.stream()
                        .flatMap(m -> m.keySet().stream().map(String::valueOf)).collect(Collectors.joining(","));

                //make sure the entity names for datamart enum values follows the same naming as the enum itself
                switch (Entity.valueOf(dmType.toUpperCase())) {
                    case HEPATITIS_DATAMART:
                        logger.info(PROCESSING_MESSAGE_TOPIC_LOG_MSG, CASE_LAB_DATAMART.getEntityName(), CASE_LAB_DATAMART.getStoredProcedure(), cases);
                        investigationRepository.executeStoredProcForCaseLabDatamart(cases);
                        completeLog(CASE_LAB_DATAMART.getStoredProcedure());

                        logger.info(PROCESSING_MESSAGE_TOPIC_LOG_MSG, dmType, HEPATITIS_DATAMART.getStoredProcedure(), cases);
                        investigationRepository.executeStoredProcForHepDatamart(cases);
                        completeLog(HEPATITIS_DATAMART.getStoredProcedure());
                        break;
                    case STD_HIV_DATAMART:
                        logger.info(PROCESSING_MESSAGE_TOPIC_LOG_MSG, dmType, STD_HIV_DATAMART.getStoredProcedure(), cases);
                        investigationRepository.executeStoredProcForStdHIVDatamart(cases);
                        completeLog(STD_HIV_DATAMART.getStoredProcedure());
                        break;
                    case GENERIC_CASE:
                        logger.info(PROCESSING_MESSAGE_TOPIC_LOG_MSG, dmType, GENERIC_CASE.getStoredProcedure(), cases);
                        investigationRepository.executeStoredProcForGenericCaseDatamart(cases);
                        completeLog(GENERIC_CASE.getStoredProcedure());
                        break;
                    case CRS_CASE:
                        logger.info(PROCESSING_MESSAGE_TOPIC_LOG_MSG, dmType, CRS_CASE.getStoredProcedure(), cases);
                        investigationRepository.executeStoredProcForCRSCaseDatamart(cases);
                        completeLog(CRS_CASE.getStoredProcedure());
                        break;
                    case RUBELLA_CASE:
                        logger.info(PROCESSING_MESSAGE_TOPIC_LOG_MSG, dmType, RUBELLA_CASE.getStoredProcedure(), cases);
                        investigationRepository.executeStoredProcForRubellaCaseDatamart(cases);
                        completeLog(RUBELLA_CASE.getStoredProcedure());
                        break;
                    case MEASLES_CASE:
                        logger.info(PROCESSING_MESSAGE_TOPIC_LOG_MSG, dmType, MEASLES_CASE.getStoredProcedure(), cases);
                        investigationRepository.executeStoredProcForMeaslesCaseDatamart(cases);
                        completeLog(MEASLES_CASE.getStoredProcedure());
                        break;
                    case CASE_LAB_DATAMART:
                        logger.info(PROCESSING_MESSAGE_TOPIC_LOG_MSG, dmType, CASE_LAB_DATAMART.getStoredProcedure(), cases);
                        investigationRepository.executeStoredProcForCaseLabDatamart(cases);
                        completeLog(CASE_LAB_DATAMART.getStoredProcedure());
                        break;
                    case BMIRD_CASE_DATAMART:
                        logger.info(PROCESSING_MESSAGE_TOPIC_LOG_MSG, dmType, BMIRD_CASE_DATAMART.getStoredProcedure(), cases);
                        investigationRepository.executeStoredProcForBmirdCaseDatamart(cases);
                        completeLog(BMIRD_CASE_DATAMART.getStoredProcedure());
                        break;
                    default:
                        logger.info("No associated datamart processing logic found for the key: {} ",dmType);
                }
            } else {
                logger.info("No data to process from the datamart topics.");
            }
        }
    }

    private void processEventMetricDatamart(List<Long> investigationUids, List<Long> observationUids, List<Long> notificationUids, List<Long> contactRecordUids) {
        String invString = investigationUids.stream().map(String::valueOf).collect(Collectors.joining(","));
        String obsString = observationUids.stream().map(String::valueOf).collect(Collectors.joining(","));
        String notifString = notificationUids.stream().map(String::valueOf).collect(Collectors.joining(","));
        String ctrString = contactRecordUids.stream().map(String::valueOf).collect(Collectors.joining(","));

        int totalLength = invString.length() + obsString.length() + notifString.length() + ctrString.length();

        if (totalLength > 0) {
            postProcRepository.executeStoredProcForEventMetric(invString, obsString, notifString, ctrString);
        }
        else {
            logger.info("No updates to EVENT_METRIC Datamart");
        }
    }

    @PreDestroy
    public void shutdown() {
        processCachedIds();
        processDatamartIds();
    }

    private String extractValFromMessage(String topic, String payload) {
        try {
            if (topic.endsWith(INVESTIGATION.getEntityName())) {
                JsonNode tblNode = objectMapper.readTree(payload).get(PAYLOAD).path("rdb_table_name_list");
                if (!tblNode.isMissingNode() && !tblNode.isNull()) {
                    return tblNode.asText();
                }
            } else if (topic.endsWith(OBSERVATION.getEntityName())) {
                String domainCd = objectMapper.readTree(payload).get(PAYLOAD).path("obs_domain_cd_st_1").asText();
                String ctrlCd = Optional.ofNullable(objectMapper.readTree(payload).get(PAYLOAD).get("ctrl_cd_display_form"))
                        .filter(node -> !node.isNull()).map(JsonNode::asText).orElse(null);

                if (MORB_REPORT.equals(ctrlCd)) {
                    if ("Order".equals(domainCd)) {
                        return ctrlCd;
                    }
                } else if (assertMatches(ctrlCd, LAB_REPORT, LAB_REPORT_MORB, null) &&
                        assertMatches(domainCd, "Order", "Result", "R_Order", "R_Result", "I_Order", "I_Result", "Order_rslt")) {
                    return LAB_REPORT;
                }
            }
        } catch (Exception ex) {
            logger.warn("Error processing ID values for the {} message: {}", topic, ex.getMessage());
        }
        return null;
    }

    private boolean assertMatches(String value, String... vals ) {
        return Arrays.asList(vals).contains(value);
    }

    /**
     * Gets the Entity by using the string passed to this function
     * E.g: if dummy_contact_record is passed, it will return the entity CONTACT_RECORD
     * @param topic
     * @return Entity
     */
    private Entity getEntityByTopic(String topic) {
        return Arrays.stream(Entity.values())
                .filter(entity -> entity.getPriority() > 0)
                .filter(entity -> topic.endsWith(entity.getEntityName()))
                .findFirst()
                .orElse(UNKNOWN);
    }

    private void processTopic(String keyTopic, Entity entity, List<Long> ids, Consumer<String> repositoryMethod) {
        processTopic(keyTopic, entity.getEntityName(), ids, repositoryMethod, entity.getStoredProcedure());
    }

    private void processTopic(String keyTopic, String name, List<Long> ids, Consumer<String> repositoryMethod, String spName) {
        String idsString = prepareAndLog(keyTopic, ids, name, spName);
        repositoryMethod.accept(idsString);
        completeLog(spName);
    }

    private <T> List<T> processTopic(String keyTopic, Entity entity, List<Long> ids,
                                     Function<String, List<T>> repositoryMethod) {
        return processTopic(keyTopic, entity.getEntityName(), ids, repositoryMethod, entity.getStoredProcedure());
    }

    private <T> List<T> processTopic(String keyTopic, String name, List<Long> ids,
                                     Function<String, List<T>> repositoryMethod, String spName) {
        String idsString = prepareAndLog(keyTopic, ids, name, spName);
        List<T> result = repositoryMethod.apply(idsString);
        completeLog(spName);
        return result;
    }

    private void processTopic(String keyTopic, Entity entity, Long id, String vals, BiConsumer<Long, String> repositoryMethod) {
        String name = entity.getEntityName();
        name = logger.isInfoEnabled() ? StringUtils.capitalize(name) : name;
        logger.info("Processing {} for topic: {}. Calling stored proc: {} '{}', '{}'", name, keyTopic,
                entity.getStoredProcedure(), id, vals);
        repositoryMethod.accept(id, vals);
        completeLog(entity.getStoredProcedure());
    }

    private String prepareAndLog(String keyTopic, List<Long> ids, String name, String spName) {
        String idsString = ids.stream().map(String::valueOf).collect(Collectors.joining(","));
        name = logger.isInfoEnabled() ? StringUtils.capitalize(name) : name;
        logger.info("Processing {} for topic: {}. Calling stored proc: {} '{}'", name, keyTopic,
                spName, idsString);
        return idsString;
    }

    private void completeLog(String sp) {
        logger.info(SP_EXECUTION_COMPLETED, sp);
    }
}
