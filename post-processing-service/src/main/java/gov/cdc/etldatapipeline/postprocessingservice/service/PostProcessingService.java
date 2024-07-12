package gov.cdc.etldatapipeline.postprocessingservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.postprocessingservice.repository.*;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.InvestigationResult;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto.Datamart;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.function.BiConsumer;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.Map.Entry;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@EnableScheduling
public class PostProcessingService {
    private static final Logger logger = LoggerFactory.getLogger(PostProcessingService.class);
    final Map<String, List<Long>> idCache = new ConcurrentHashMap<>();
    final Map<Long, String> idVals = new ConcurrentHashMap<>();
    final Map<String, Set<Map<Long, Long>>> dmCache = new ConcurrentHashMap<>();

    private final PatientRepository patientRepository;
    private final ProviderRepository providerRepository;
    private final OrganizationRepository organizationRepository;
    private final InvestigationRepository investigationRepository;
    private final NotificationRepository notificationRepository;

    private final ProcessDatamartData datamartProcessor;

    static final String PAYLOAD = "payload";
    static final String SP_EXECUTION_COMPLETED = "Stored proc execution completed";

    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    @Getter
    private enum Entity {
        ORGANIZATION(1, "organization", "organization_uid", "sp_nrt_organization_postprocessing"),
        PROVIDER(2, "provider", "provider_uid", "sp_nrt_provider_postprocessing"),
        PATIENT(3, "patient", "patient_uid", "sp_nrt_patient_postprocessing"),
        INVESTIGATION(4, "investigation", "public_health_case_uid", "sp_nrt_investigation_postprocessing"),
        NOTIFICATIONS(5, "notifications", "notification_uid", "sp_nrt_notification_postprocessing"),
        F_PAGE_CASE(0, "investigation", "public_health_case_uid", "sp_f_page_case_postprocessing"),
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

    @KafkaListener(topics = {
            "${spring.kafka.topic.investigation}",
            "${spring.kafka.topic.organization}",
            "${spring.kafka.topic.patient}",
            "${spring.kafka.topic.provider}",
            "${spring.kafka.topic.notification}"
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

    @KafkaListener(topics = {"${spring.kafka.topic.datamart}"})
    public void postProcessDatamart(
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Payload String payload) {
        try {
            JsonNode payloadNode = objectMapper.readTree(payload);
            logger.info("Got this payload: {} from the topic: {}", payloadNode, topic);

            Datamart dmData = objectMapper.readValue(payloadNode.get(PAYLOAD).toString(), Datamart.class);
            Map<Long, Long> dmMap = new HashMap<>();
            dmMap.put(dmData.getPublicHealthCaseUid(), dmData.getPatientUid());
            dmCache.computeIfAbsent(dmData.getDatamart(), k -> ConcurrentHashMap.newKeySet()).add(dmMap);
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
            if(!entry.getValue().isEmpty()) {
                String keyTopic = entry.getKey();
                List<Long> ids = entry.getValue();
                idCache.put(keyTopic, new ArrayList<>());

                Entity entity = getEntityByTopic(keyTopic);
                switch (entity) {
                    case ORGANIZATION:
                        processTopic(keyTopic, entity, ids, organizationRepository::executeStoredProcForOrganizationIds);
                        break;
                    case PROVIDER:
                        processTopic(keyTopic, entity, ids, providerRepository::executeStoredProcForProviderIds);
                        break;
                    case PATIENT:
                        processTopic(keyTopic, entity, ids, patientRepository::executeStoredProcForPatientIds);
                        break;
                    case INVESTIGATION:
                        List<InvestigationResult> invData = processTopic(keyTopic, entity, ids, investigationRepository::executeStoredProcForPublicHealthCaseIds);
                        ids.forEach(id -> {
                            if (idVals.containsKey(id)) {
                                processId(id, idVals.get(id), investigationRepository::executeStoredProcForPageBuilder, Entity.CASE_ANSWERS);
                                idVals.remove(id);
                            }
                        });
                        processTopic(keyTopic, Entity.F_PAGE_CASE, ids, investigationRepository::executeStoredProcForFPageCase);
                        datamartProcessor.process(invData);
                        break;
                    case NOTIFICATIONS:
                        processTopic(keyTopic, entity, ids, notificationRepository::executeStoredProcForNotificationIds);
                        break;
                    default:
                        logger.warn("Unknown topic: {} cannot be processed", keyTopic);
                        break;
                }
            }
            else {
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
                    String cases = dmSet.stream().flatMap(m -> m.keySet().stream().map(String::valueOf)).collect(Collectors.joining(","));
                    String patients = dmSet.stream().flatMap(m -> m.values().stream().map(String::valueOf)).collect(Collectors.joining(","));

                    logger.info("Processing the {} message topic. Calling stored proc: {}('{}','{}')", dmType, "sp_hepatitis_datamart_postprocessing", cases, patients);
                    investigationRepository.executeStoredProcForHepDatamart(cases, patients);
                    completeLog();
                }
            }
            else {
                logger.info("No data to process from the datamart topics.");
            }
        }
    }

    Long extractIdFromMessage(String topic, String messageKey, String payload) {
        Long id;
        try {
            JsonNode keyNode = objectMapper.readTree(messageKey);
            JsonNode payloadNode = objectMapper.readTree(payload);
            logger.info("Got this key payload: {} from the topic: {}", messageKey, topic);

            Entity entity = getEntityByTopic(topic);
            id = keyNode.get(PAYLOAD).get(entity.getUidName()).asLong();

            if(topic.contains(Entity.INVESTIGATION.getName())) {
                JsonNode tblNode = payloadNode.get(PAYLOAD).get("rdb_table_name_list");
                if (tblNode != null && !tblNode.isNull()) {
                    idVals.put(id, tblNode.asText());
                }
            }
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return id;
    }

    private Entity getEntityByTopic(String topic) {
        return Arrays.stream(Entity.values())
                .filter(entity -> entity.getPriority() > 0)
                .filter(entity -> topic.contains(entity.getName()))
                .findFirst()
                .orElse(Entity.UNKNOWN);
    }


    private void processTopic(String keyTopic, Entity entity, List<Long> ids, Consumer<String> repositoryMethod) {
        String idsString = prepareAndLog(keyTopic, entity, ids);
        repositoryMethod.accept(idsString);
        completeLog();
    }

    private <T> List<T> processTopic(String keyTopic, Entity entity, List<Long> ids, Function<String, List<T>> repositoryMethod) {
        String idsString = prepareAndLog(keyTopic, entity, ids);
        List<T> result = repositoryMethod.apply(idsString);
        completeLog();
        return result;
    }

    private String prepareAndLog(String keyTopic, Entity entity, List<Long> ids) {
        String idsString = ids.stream().map(String::valueOf).collect(Collectors.joining(","));
        logger.info("Processing the {} message topic: {}. Calling stored proc: {}('{}')", entity.getName(), keyTopic, entity.getStoredProcedure(), idsString);
        return idsString;
    }

    private void processId(Long id, String vals,BiConsumer<Long, String> repositoryMethod, Entity entity) {
        logger.info("Processing PHC ID for {}. Calling stored proc: {}({}, '{}')", entity.getName(), entity.getStoredProcedure(), id, vals);
        repositoryMethod.accept(id, vals);
        completeLog();
    }

    private void completeLog() {
        logger.info(SP_EXECUTION_COMPLETED);
    }
}
