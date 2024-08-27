package gov.cdc.etldatapipeline.postprocessingservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.NoDataException;
import gov.cdc.etldatapipeline.postprocessingservice.repository.*;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.InvestigationResult;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto.Datamart;
import lombok.Getter;
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
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.function.BiConsumer;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@EnableScheduling
public class PostProcessingService {
    private static final Logger logger = LoggerFactory.getLogger(PostProcessingService.class);
    final Map<String, List<Long>> idCache = new ConcurrentHashMap<>();
    final Map<Long, String> idVals = new ConcurrentHashMap<>();
    final Map<String, Set<Map<Long, Long>>> dmCache = new ConcurrentHashMap<>();

    private final PostProcRepository postProcRepository;
    private final InvestigationRepository investigationRepository;

    private final ProcessDatamartData datamartProcessor;

    static final String PAYLOAD = "payload";
    static final String SP_EXECUTION_COMPLETED = "Stored proc execution completed: {}";

    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    @Getter
    enum Entity {
        ORGANIZATION(1, "organization", "organization_uid", "sp_nrt_organization_postprocessing"),
        PROVIDER(2, "provider", "provider_uid", "sp_nrt_provider_postprocessing"),
        PATIENT(3, "patient", "patient_uid", "sp_nrt_patient_postprocessing"),
        INVESTIGATION(4, "investigation", "public_health_case_uid", "sp_nrt_investigation_postprocessing"),
        NOTIFICATION(5, "notification", "notification_uid", "sp_nrt_notification_postprocessing"),
        LDF_DATA(6, "ldf_data", "ldf_uid", "sp_nrt_ldf_postprocessing"),
        F_PAGE_CASE(0, "fact page case", "public_health_case_uid", "sp_f_page_case_postprocessing"),
        CASE_ANSWERS(0, "case answers", "public_health_case_uid", "sp_page_builder_postprocessing"),
        UNKNOWN(-1, "unknown", "unknown_uid", "sp_nrt_unknown_postprocessing");

        private final int priority;
        private final String name;
        private final String storedProcedure;
        private final String uidName;

        Entity(int priority, String name, String uidName, String storedProcedure) {
            this.priority = priority;
            this.name = name;
            this.storedProcedure = storedProcedure;
            this.uidName = uidName;
        }
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
    @KafkaListener(topics = {
            "${spring.kafka.topic.investigation}",
            "${spring.kafka.topic.organization}",
            "${spring.kafka.topic.patient}",
            "${spring.kafka.topic.provider}",
            "${spring.kafka.topic.notification}",
            "${spring.kafka.topic.ldf_data}"
    })
    public void postProcessMessage(
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_KEY) String key,
            @Payload String payload) {
        Long id = extractIdFromMessage(topic, key, payload);
        if (id != null) {
            idCache.computeIfAbsent(topic, k -> new CopyOnWriteArrayList<>()).add(id);
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
                    RuntimeException.class,
                    NoDataException.class
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
            final String PAYLOAD_PFX = "For payload: " + payloadNode;
            if (Objects.isNull(dmData)) {
                throw new NoDataException(PAYLOAD_PFX + " DataMart object is null. Skipping further processing");
            }
            Map<Long, Long> dmMap = new HashMap<>();
            if (Objects.isNull(dmData.getPublicHealthCaseUid()) || Objects.isNull(dmData.getPatientUid())) {
                throw new NoDataException(PAYLOAD_PFX + " DataMart Public Health Case/Patient Id is null. Skipping further processing");
            }
            dmMap.put(dmData.getPublicHealthCaseUid(), dmData.getPatientUid());
            if (Objects.isNull(dmData.getDatamart())) {
                throw new NoDataException(PAYLOAD_PFX + " DataMart value is null. Skipping further processing");
            }
            dmCache.computeIfAbsent(dmData.getDatamart(), k -> ConcurrentHashMap.newKeySet()).add(dmMap);
        } catch (NoDataException nde) {
            logger.warn(nde.getMessage());
            throw nde;
        } catch (Exception e) {
            logger.error("Error processing datamart message: {}", e.getMessage());
            throw new RuntimeException(e);
        }
    }

    @Scheduled(fixedDelayString = "${service.fixed-delay.cached-ids}")
    protected void processCachedIds() {
        List<Entry<String, List<Long>>> sortedEntries = idCache.entrySet().stream()
                .sorted(Comparator.comparingInt(entry -> getEntityByTopic(entry.getKey()).getPriority())).toList();

        for (Entry<String, List<Long>> entry : sortedEntries) {
            if (!entry.getValue().isEmpty()) {
                String keyTopic = entry.getKey();
                List<Long> ids = entry.getValue();
                idCache.put(keyTopic, new ArrayList<>());

                logger.info("Processing {} id(s) from topic: {}", ids.size(), keyTopic);

                Entity entity = getEntityByTopic(keyTopic);
                switch (entity) {
                    case ORGANIZATION:
                        processTopic(keyTopic, entity, ids,
                                postProcRepository::executeStoredProcForOrganizationIds);
                        break;
                    case PROVIDER:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForProviderIds);
                        break;
                    case PATIENT:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForPatientIds);
                        break;
                    case INVESTIGATION:
                        List<InvestigationResult> invData = processTopic(keyTopic, entity, ids,
                                investigationRepository::executeStoredProcForPublicHealthCaseIds);

                        ids.forEach(id -> {
                            if (idVals.containsKey(id)) {
                                processTopic(keyTopic, Entity.CASE_ANSWERS, id, idVals.get(id),
                                        investigationRepository::executeStoredProcForPageBuilder);
                                idVals.remove(id);
                            }
                        });

                        processTopic(keyTopic, Entity.F_PAGE_CASE, ids,
                                investigationRepository::executeStoredProcForFPageCase);
                        datamartProcessor.process(invData);
                        break;
                    case NOTIFICATION:
                        processTopic(keyTopic, entity, ids,
                                postProcRepository::executeStoredProcForNotificationIds);
                        break;
                    case LDF_DATA:
                        processTopic(keyTopic, entity, ids,
                                postProcRepository::executeStoredProcForLdfIds);
                        break;
                    default:
                        logger.warn("Unknown topic: {} cannot be processed", keyTopic);
                        break;
                }
            } else {
                logger.info("No ids to process from the topics.");
            }
        }
    }

    @Scheduled(fixedDelayString = "${service.fixed-delay.datamart}")
    protected void processDatamartIds() {
        for (Map.Entry<String, Set<Map<Long, Long>>> entry : dmCache.entrySet()) {
            if (!entry.getValue().isEmpty()) {
                String dmType = entry.getKey();
                Set<Map<Long, Long>> dmSet = entry.getValue();
                dmCache.put(dmType, ConcurrentHashMap.newKeySet());

                if (dmType.equals("Hepatitis_Datamart")) {
                    String cases =
                            dmSet.stream().flatMap(m -> m.keySet().stream().map(String::valueOf)).collect(Collectors.joining(","));
                    String patients =
                            dmSet.stream().flatMap(m -> m.values().stream().map(String::valueOf)).collect(Collectors.joining(","));

                    logger.info("Processing {} message topic. Calling stored proc: {} '{}','{}'", dmType,
                            "sp_hepatitis_datamart_postprocessing", cases, patients);
                    investigationRepository.executeStoredProcForHepDatamart(cases, patients);
                    completeLog("sp_hepatitis_datamart_postprocessing");
                }
            } else {
                logger.info("No data to process from the datamart topics.");
            }
        }
    }

    Long extractIdFromMessage(String topic, String messageKey, String payload) {
        Long id;
        try {
            logger.info("Got this key payload: {} from the topic: {}", messageKey, topic);
            JsonNode keyNode = objectMapper.readTree(messageKey);
            JsonNode payloadNode = objectMapper.readTree(payload);

            Entity entity = getEntityByTopic(topic);
            if (Objects.isNull(keyNode.get(PAYLOAD).get(entity.getUidName()))) {
                throw new NoDataException("Null value found for key '" + entity.getUidName() + "' in topic '" + topic + "'");
            }
            id = keyNode.get(PAYLOAD).get(entity.getUidName()).asLong();

            if (entity.equals(Entity.INVESTIGATION)) {
                JsonNode tblNode = payloadNode.get(PAYLOAD).get("rdb_table_name_list");
                if (tblNode != null && !tblNode.isNull()) {
                    idVals.put(id, tblNode.asText());
                }
            }
        } catch (NoDataException nde) {
            logger.warn(nde.getMessage());
            throw nde;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return id;
    }

    private Entity getEntityByTopic(String topic) {
        return Arrays.stream(Entity.values())
                .filter(entity -> entity.getPriority() > 0)
                .filter(entity -> topic.endsWith(entity.getName()))
                .findFirst()
                .orElse(Entity.UNKNOWN);
    }

    private void processTopic(String keyTopic, Entity entity, List<Long> ids, Consumer<String> repositoryMethod) {
        String idsString = prepareAndLog(keyTopic, entity, ids);
        repositoryMethod.accept(idsString);
        completeLog(entity.getStoredProcedure());
    }

    private <T> List<T> processTopic(String keyTopic, Entity entity, List<Long> ids,
                                     Function<String, List<T>> repositoryMethod) {
        String idsString = prepareAndLog(keyTopic, entity, ids);
        List<T> result = repositoryMethod.apply(idsString);
        completeLog(entity.getStoredProcedure());
        return result;
    }

    private void processTopic(String keyTopic, Entity entity, Long id, String vals, BiConsumer<Long, String> repositoryMethod) {
        logger.info("Processing {} for topic: {}. Calling stored proc: {} '{}', '{}'", StringUtils.capitalize(entity.getName()), keyTopic,
                entity.getStoredProcedure(), id, vals);
        repositoryMethod.accept(id, vals);
        completeLog(entity.getStoredProcedure());
    }

    private String prepareAndLog(String keyTopic, Entity entity, List<Long> ids) {
        String idsString = ids.stream().map(String::valueOf).collect(Collectors.joining(","));
        logger.info("Processing {} for topic: {}. Calling stored proc: {} '{}'", StringUtils.capitalize(entity.getName()), keyTopic,
                entity.getStoredProcedure(), idsString);
        return idsString;
    }

    private void completeLog(String sp) {
        logger.info(SP_EXECUTION_COMPLETED, sp);
    }
}
