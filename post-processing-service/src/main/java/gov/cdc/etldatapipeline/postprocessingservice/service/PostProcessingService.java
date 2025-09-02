package gov.cdc.etldatapipeline.postprocessingservice.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.DataProcessingException;
import gov.cdc.etldatapipeline.commonutil.metrics.CustomMetrics;
import gov.cdc.etldatapipeline.postprocessingservice.repository.*;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.BackfillData;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.DatamartData;
import gov.cdc.etldatapipeline.postprocessingservice.repository.model.dto.Datamart;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Timer;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.apache.kafka.common.errors.SerializationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
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
import java.util.HashMap;
import java.util.Queue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.Arrays;
import java.util.function.*;
import java.util.stream.Collectors;
import java.util.Map.Entry;
import java.util.stream.Stream;

import static gov.cdc.etldatapipeline.commonutil.UtilHelper.errorMessage;
import static gov.cdc.etldatapipeline.postprocessingservice.service.Entity.*;
import static gov.cdc.etldatapipeline.postprocessingservice.service.ProcessDatamartData.MULTI_ID_DATAMART;
import static gov.cdc.etldatapipeline.postprocessingservice.service.ProcessDatamartData.STATUS_READY;

@Service
@RequiredArgsConstructor
@Setter
@EnableScheduling
public class PostProcessingService {
    private static final Logger logger = LoggerFactory.getLogger(PostProcessingService.class);

    // cache to store ids from nrt topics that needs to be processed for loading dims and facts
    // a map of nrt topic name and its associated ids
    final Map<String, Queue<Long>> idCache = new ConcurrentHashMap<>();

    // cache to store information from topics with key values that need to be type String as opposed to Long
    // a map of nrt topic name and its associated cds
    final Map<String, Queue<String>> cdCache = new ConcurrentHashMap<>();

    // cache to store PHC ids from for specific case types to run summary and aggregate reports
    // a map of the case type (sum/agg) and its associated ids
    final Map<String, Queue<Long>> sumCache = new ConcurrentHashMap<>();

    // cache to store rdb_table -> phc uids mapping for page_builder post-processing
    final Map<String, Queue<Long>> pbCache = new ConcurrentHashMap<>();

    // cache to store report_type -> obs uids mapping for morb report and lab test post-processing
    final Map<String, Queue<Long>> obsCache = new ConcurrentHashMap<>();

    // cache to store ids that needs to be processed for datamarts
    // a map of datamart names and the necessary ids
    final Map<String, Map<String, Queue<Long>>> dmCache = new ConcurrentHashMap<>();

    // set of caches for retrying failed topics/IDs and tracking retry attempts
    final Map<Long, Map<String, Queue<Long>>> retryCache = new ConcurrentHashMap<>();

    @Value("${service.max-retries}")
    private int maxRetries;

    private final PostProcRepository postProcRepository;
    private final InvestigationRepository investigationRepository;

    private final ProcessDatamartData dmProcessor;

    static final String PAYLOAD = "payload";
    static final String SP_EXECUTION_COMPLETED = "Stored proc execution completed: {}";
    static final String UNKNOWN_TOPIC_LOG_MSG = "Unknown topic: {} cannot be processed";
    static final String PROCESSING_IDS_LOG_MSG = "Processing {} id(s) from topic: {}";

    static final String MORB_REPORT = "MorbReport";
    static final String LAB_REPORT = "LabReport";
    static final String LAB_REPORT_MORB = "LabReportMorb";

    static final String CASE_TYPE_SUM = "Summary";
    static final String CASE_TYPE_AGG = "Aggregate";
    static final String ACT_TYPE_SUM = "SummaryNotification";

    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
    private final Object cacheLock = new Object();

    @Value("${spring.kafka.topic.investigation}")
    private String investigationTopic;

    private static final String SERVICE_NAME = "post-process-reporting";

    private final CustomMetrics metrics;

    private Counter ppMsgProcessed;
    private Counter ppMsgSuccess;
    private Counter ppMsgFailure;

    private Counter dmMsgProcessed;

    Timer processTimer;
    private final AtomicInteger cacheSizeGauge = new AtomicInteger();

    @PostConstruct
    void initMetrics() {
        String[] tags = {"service", SERVICE_NAME};

        ppMsgProcessed = metrics.counter("post_msg_processed", tags);
        ppMsgSuccess = metrics.counter( "post_msg_success", tags);
        ppMsgFailure = metrics.counter("post_msg_failure", tags);

        dmMsgProcessed = metrics.counter("dm_msg_processed", tags);
        dmMsgSuccess = metrics.counter( "dm_msg_success", tags);
        dmMsgFailure = metrics.counter("dm_msg_failure", tags);

        processTimer = metrics.timer("post_batch_processing_seconds", tags);
        metrics.gauge("post_batch_size", cacheSizeGauge, AtomicInteger::doubleValue, tags);
    }

    /**
     * Processes a message from a Kafka topic. This method is the entry point for handling messages
     * from Kafka topics.
     * <p>Steps:
     * <ul>1. Identify the entity type based on the topic.</ul>
     * <ul>2. Extract relevant IDs or data from the message payload.</ul>
     * <ul>3. Cache the extracted IDs for further processing in idCache and data in idVals.</ul>
     *
     * @param topic The name of the Kafka topic from which the message was received.
     * @param key The key of the Kafka message, typically used for partitioning.
     * @param payload The value of the Kafka message, which contains the payload to be processed.
     */
    @RetryableTopic(
            attempts = "${spring.kafka.consumer.max-retry}",
            autoCreateTopics = "false",
            dltStrategy = DltStrategy.FAIL_ON_ERROR,
            retryTopicSuffix = "${spring.kafka.dlq.retry-suffix}",
            dltTopicSuffix = "${spring.kafka.dlq.dlq-suffix}",
            // retry topic name, such as topic-retry-1, topic-retry-2, etc
            topicSuffixingStrategy = TopicSuffixingStrategy.SUFFIX_WITH_INDEX_VALUE,
            // time to wait before attempting to retry
            backoff = @Backoff(delay = 1000, multiplier = 2.0), exclude = {
                    SerializationException.class,
                    DeserializationException.class,
                    RuntimeException.class
            })
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
            "${spring.kafka.topic.auth_user}",
            "${spring.kafka.topic.contact_record}",
            "${spring.kafka.topic.treatment}",
            "${spring.kafka.topic.vaccination}",
            "${spring.kafka.topic.state_defined_field_metadata}",
            "${spring.kafka.topic.page}",
            "${spring.kafka.topic.condition}"
    })
    public void processNrtMessage(
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_KEY) String key,
            @Payload String payload) {
        ppMsgProcessed.increment();
        extractIdFromMessage(topic, key, payload);
    }

    /**
     * Extract id from the kafka message key
     * @param topic
     * @param messageKey
     * @param payload
     */
    private void extractIdFromMessage(String topic, String messageKey, String payload) {
        try {
            logger.info("Got this key payload: {} from the topic: {}", messageKey, topic);
            JsonNode keyNode = objectMapper.readTree(messageKey);

            Entity entity = getEntityByTopic(topic);
            if (Objects.isNull(keyNode.get(PAYLOAD).get(entity.getUidName()))) {
                throw new NoSuchElementException(
                        "The '" + entity.getUidName() + "' value is missing in the '" + topic + "' message payload.");
            }
            JsonNode idNode = keyNode.get(PAYLOAD).get(entity.getUidName());

            if (idNode.isTextual()) {
                String cd = idNode.asText();
                cdCache.computeIfAbsent(topic, k -> new ConcurrentLinkedQueue<>()).add(cd);
            }
            else {
                Long id = idNode.asLong();
                idCache.computeIfAbsent(topic, k -> new ConcurrentLinkedQueue<>()).add(id);
                extractValFromMessage(id, topic, payload);
            }

        } catch (Exception e) {
            String msg = "Error processing '" + topic + "'  message: " + e.getMessage();
            throw new DataProcessingException(msg, e);
        }
    }
    /**
     * Extracts relevant value from the kafka message payload
     * @param uid
     * @param topic
     * @param payload
     */
    private void extractValFromMessage(Long uid, String topic, String payload) {
        try {
            JsonNode payloadNode = objectMapper.readTree(payload).get(PAYLOAD);
            if (topic.endsWith(INVESTIGATION.getEntityName())) {
                extractSummaryCase(uid, payloadNode.path("case_type_cd").asText());

                JsonNode tblNode = payloadNode.path("rdb_table_name_list");
                if (!tblNode.isMissingNode() && !tblNode.isNull()) {
                    Arrays.stream(tblNode.asText().split(",")).map(String::trim).forEach(tbl ->
                        pbCache.computeIfAbsent(tbl, k -> new ConcurrentLinkedQueue<>()).add(uid));

                }
            } else if (topic.endsWith(NOTIFICATION.getEntityName())) {
                String actTypeCd = payloadNode.path("act_type_cd").asText();
                Long phcUid = payloadNode.get(INVESTIGATION.getUidName()).asLong();
                extractSummaryCase(phcUid, actTypeCd);
            } else if (topic.endsWith(OBSERVATION.getEntityName())) {
                String domainCd = payloadNode.path("obs_domain_cd_st_1").asText();
                String ctrlCd = Optional
                        .ofNullable(payloadNode.get("ctrl_cd_display_form"))
                        .filter(node -> !node.isNull()).map(JsonNode::asText).orElse(null);

                if (MORB_REPORT.equals(ctrlCd)) {
                    if ("Order".equals(domainCd)) {
                        obsCache.computeIfAbsent(MORB_REPORT, k -> new ConcurrentLinkedQueue<>()).add(uid);
                    }
                } else if (assertMatches(ctrlCd, LAB_REPORT, LAB_REPORT_MORB, null) &&
                        assertMatches(domainCd, "Order", "Result", "R_Order", "R_Result", "I_Order", "I_Result",
                                "Order_rslt")) {
                    obsCache.computeIfAbsent(LAB_REPORT, k -> new ConcurrentLinkedQueue<>()).add(uid);
                }
            }
        } catch (Exception ex) {
            logger.warn("Error processing ID values for the {} message: {}", topic, ex.getMessage());
        }
    }

    private void extractSummaryCase(Long uid, String caseType) {
        if (ACT_TYPE_SUM.equals(caseType) || "S".equals(caseType)) {
            sumCache.computeIfAbsent(CASE_TYPE_SUM, k -> new ConcurrentLinkedQueue<>()).add(uid);
        }
        if (ACT_TYPE_SUM.equals(caseType) || "A".equals(caseType)) {
            sumCache.computeIfAbsent(CASE_TYPE_AGG, k -> new ConcurrentLinkedQueue<>()).add(uid);
        }
    }

    @RetryableTopic(
        attempts = "${spring.kafka.consumer.max-retry}",
        autoCreateTopics = "false",
        dltStrategy = DltStrategy.FAIL_ON_ERROR,
        retryTopicSuffix = "${spring.kafka.dlq.retry-suffix}",
        dltTopicSuffix = "${spring.kafka.dlq.dlq-suffix}",
        topicSuffixingStrategy = TopicSuffixingStrategy.SUFFIX_WITH_INDEX_VALUE,
        backoff = @Backoff(delay = 1000, multiplier = 2.0), exclude = {
            SerializationException.class,
            DeserializationException.class,
            RuntimeException.class
    })
    @KafkaListener(topics = { "${spring.kafka.topic.datamart}" })
    public void processDmMessage(
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Payload String payload) {
        try {
            dmMsgProcessed.increment();
            logger.info("Got this payload: {} from the topic: {}", payload, topic);
            JsonNode payloadNode = objectMapper.readTree(payload);

            Datamart dmData = objectMapper.readValue(payloadNode.get(PAYLOAD).toString(), Datamart.class);
            if (Objects.isNull(dmData)) {
                logger.info("For payload: {} DataMart object is null. Skipping further processing", payloadNode);
                return;
            }
            if (Objects.isNull(dmData.getPublicHealthCaseUid()) || Objects.isNull(dmData.getPatientUid())) {
                logger.info(
                        "For payload: {} DataMart Case/Patient Id is null. Skipping further processing", payloadNode);
                return;
            }
            if (Objects.isNull(dmData.getDatamart())) {
                logger.info("For payload: {} DataMart value is null. Skipping further processing", payloadNode);
                return;
            }

            Map<String, Queue<Long>> dmMap = dmCache.computeIfAbsent(dmData.getDatamart(), k -> new ConcurrentHashMap<>());

            dmMap.computeIfAbsent(INVESTIGATION.getEntityName(),
                    k -> new ConcurrentLinkedQueue<>()).add(dmData.getPublicHealthCaseUid());

            Optional.ofNullable(dmData.getPatientUid()).ifPresent(uid ->
                    dmMap.computeIfAbsent(PATIENT.getEntityName(), k -> new ConcurrentLinkedQueue<>()).add(uid));

            Optional.ofNullable(dmData.getObservationUid()).ifPresent(uid ->
                    dmMap.computeIfAbsent(OBSERVATION.getEntityName(), k -> new ConcurrentLinkedQueue<>()).add(uid));

        } catch (Exception e) {
            String msg = "Error processing datamart message: " + e.getMessage();
            throw new DataProcessingException(msg, e);
        }
    }

    /**
     * Processes all cached IDs for various entities (e.g., investigations, notifications, organizations)
     * and executes the appropriate stored procedures for each entity type. This method triggers at fixed intervals and
     * consolidates the processing of IDs collected from multiple Kafka messages.
     * <p>
     * Steps:
     * <ul>1. Iterate through cached IDs grouped by entity type.</ul>
     * <ul>2. Execute the corresponding stored procedure for each entity type.</ul>
     * <ul>3. Log the execution status for debugging and monitoring purposes.</ul>
     * <ul>4. Store the entity name and ids for later if needed for data marts (both direct dependent and also for multi-id datamarts).</ul>
     * <ul>5. Process event metric and summary datamarts</ul>
     * <ul>6. Send the event message to the kafka topic that handles data mart events for building other datamarts</ul>
     */
    @Scheduled(fixedDelayString = "${service.fixed-delay.cached-ids}")
    protected void processCachedIds() {

        // Making a cache snapshots preventing out-of-sequence ids processing
        // creates a deep copy of caches into snapshots
        final Map<String, List<Long>> idCacheSnapshot;
        final Map<String, List<String>> cdCacheSnapshot;
        final Map<String, List<Long>> pbCacheSnapshot;
        final Map<String, List<Long>> obsCacheSnapshot;

        synchronized (cacheLock) {
            idCacheSnapshot = idCache.entrySet().stream()
                    .collect(Collectors.toMap(Map.Entry::getKey, entry -> new ArrayList<>(entry.getValue())));
            idCache.clear();

            cdCacheSnapshot = cdCache.entrySet().stream()
                    .collect(Collectors.toMap(Map.Entry::getKey, entry -> new ArrayList<>(entry.getValue())));
            cdCache.clear();

            pbCacheSnapshot = pbCache.entrySet().stream()
                    .collect(Collectors.toMap(Map.Entry::getKey, entry -> new ArrayList<>(entry.getValue())));
            pbCache.clear();

            obsCacheSnapshot = obsCache.entrySet().stream()
                    .collect(Collectors.toMap(Map.Entry::getKey, entry -> new ArrayList<>(entry.getValue())));
            obsCache.clear();
        }

        int cacheSize =
                idCacheSnapshot.values().stream().mapToInt(List::size).sum() +
                cdCacheSnapshot.values().stream().mapToInt(List::size).sum();
        cacheSizeGauge.set(cacheSize);

        if (cacheSize > 0) {
            Timer.Sample sample = metrics.startSample();
            try {
                processCdCache(cdCacheSnapshot);
                if (!idCacheSnapshot.isEmpty()) {
                    processIdCache(idCacheSnapshot, pbCacheSnapshot, obsCacheSnapshot, null);
                }
            } finally {
                metrics.stopSample(sample, processTimer);
            }
        } else {
            logger.info("No ids to process from the topics.");
        }
    }

    /**
     * Scheduled task to reprocess failed entities by iterating through retry cache and invoking {@link #processIdCache(Map, Map, Map, Long)}
     * with snapshots of the cached IDs.
     * <ul>1. Updates backfill records, manages retry attempts</ul>
     * <ul>2. Clear caches on success</ul>
     * <ul>3. Persists remaining IDs when the maximum retry limit is reached</ul>
     */
    @Scheduled(fixedDelayString = "${service.fixed-delay.cached-ids}")
    protected void processRetryCache() {
        Map<Long, Integer> retryAttempts = dmProcessor.retryAttempts;
        Map<Long, String> errorMap = dmProcessor.errorMap;

        for(Entry<Long, Map<String, Queue<Long>>> retryEntry : retryCache.entrySet()) {

            Long batchId = retryEntry.getKey();

            // Making a cache snapshot preventing out-of-sequence ids processing
            // creates a deep copy of cache into snapshot
            final Map<String, List<Long>> idCacheSnapshot;
            final Map<String, List<Long>> pbCacheSnapshot;
            final Map<String, List<Long>> obsCacheSnapshot;

            synchronized (cacheLock) {
                idCacheSnapshot = retryEntry.getValue().entrySet().stream()
                        .filter(entry -> !entry.getKey().contains("^"))
                        .collect(Collectors.toMap(Map.Entry::getKey, entry -> new ArrayList<>(entry.getValue())));

                pbCacheSnapshot = retryEntry.getValue().entrySet().stream()
                        .filter(e -> e.getKey().startsWith("PB^"))
                        .collect(Collectors.toMap(
                                e -> e.getKey().substring("PB^".length()),
                                e -> new ArrayList<>(e.getValue())
                        ));

                obsCacheSnapshot = retryEntry.getValue().entrySet().stream()
                        .filter(e -> e.getKey().startsWith("OBS^"))
                        .collect(Collectors.toMap(
                                e -> e.getKey().substring("OBS^".length()),
                                e -> new ArrayList<>(e.getValue())
                        ));

                retryCache.remove(batchId);
            }

            boolean processed = processIdCache(idCacheSnapshot, pbCacheSnapshot, obsCacheSnapshot, batchId);

            // update backfill batch record(s) if exists
            if (dmProcessor.updateBackfills(batchId, processed)) {
                retryCache.remove(batchId);
                continue;
            }

            if (processed) {
                // clear retry caches if no errors after re-processing
                retryAttempts.remove(batchId);
                errorMap.remove(batchId);
            } else {
                int attempt = retryAttempts.getOrDefault(batchId, 0);
                if (attempt >= maxRetries) {
                    logger.info("Reached max retries for batch id: {}. Skipping further processing.", batchId);
                    retryAttempts.remove(batchId);
                    retryCache.remove(batchId);

                    dmProcessor.processBackfills(idCacheSnapshot, key -> getEntityByTopic(key).getEntityName().toUpperCase(), batchId);
                    dmProcessor.processBackfills(pbCacheSnapshot, key -> "PB^" + key, batchId);
                    dmProcessor.processBackfills(obsCacheSnapshot, key -> "OBS^" + key, batchId);

                    errorMap.remove(batchId);
                }
            }
        }
    }

    @Scheduled(fixedDelayString = "${service.fixed-delay.backfill}")
    protected void backfillEvent() {
        //skip processing for non-positive value
        if (maxRetries <= 0) {
            return;
        }

        List<BackfillData> backfills = postProcRepository.executeBackfillEvent(STATUS_READY);
        if (backfills.isEmpty()) {
            logger.info("No backfill records found.");
            return;
        }

        // Build a temporary map: batchId -> (entity -> queue of UIDs)
        Map<Long, Map<String, Queue<Long>>> retryCacheLocal = new HashMap<>();
        backfills.forEach(bf -> {
            Long batchId = bf.getBatchId();

            String bfe = bf.getEntity();
            if (bfe.startsWith("DM^")) {
                dmProcessor.updateRetryCache(batchId, bf);
            } else {
                String entity = bfe.contains("^") ? bfe : "nrt_" + bfe.toLowerCase();
                Queue<Long> queue = Arrays.stream(bf.getRecordUidList().split(","))
                        .map(Long::valueOf)
                        .collect(Collectors.toCollection(ConcurrentLinkedQueue::new));
                retryCacheLocal
                        .computeIfAbsent(batchId, k -> new HashMap<>())
                        .computeIfAbsent(entity, k -> new ConcurrentLinkedQueue<>())
                        .addAll(queue);
                dmProcessor.backfillAttempts.put(batchId, bf.getRetryCount());
                dmProcessor.retryAttempts.put(batchId, bf.getRetryCount());
                dmProcessor.errorMap.put(batchId, bf.getErrDescription());
            }
        });

        // Merge into the main retryCache for reprocessing, preserving batch IDs
        retryCacheLocal.forEach((batchId, entityMap) -> {
            Map<String, Queue<Long>> batchMap = retryCache.computeIfAbsent(batchId, k -> new ConcurrentHashMap<>());
            entityMap.forEach((entity, queue) ->
                batchMap.computeIfAbsent(entity, k -> new ConcurrentLinkedQueue<>()).addAll(queue)
            );
        });

        logger.info("Re-queued {} backfill batch(es) into retryCache", backfills.size());
    }

    private boolean processIdCache(
            Map<String, List<Long>> idCache, Map<String, List<Long>> pbCache, Map<String, List<Long>> obsCache, Long batchId) {

        // sorting idCacheSnapshot so that entities with higher priority is processed first
        List<Entry<String, List<Long>>> sortedEntries = idCache.entrySet().stream()
                .sorted(Comparator.comparingInt(entry -> getEntityByTopic(entry.getKey()).getPriority())).toList();

        // list to store details of datamarts and the associated ids that needs to be hydrated downstream
        List<DatamartData> dmData = new ArrayList<>();

        // list to keep volatile datamart data to be merged into dmData
        List<DatamartData> dmDataSp = new ArrayList<>();

        // Isolated temporary map to accumulate entity ID collections by entity type.
        // After processing, it is merged into dmCache for multi-ID datamarts invocation.
        // Isolation prevents conflicts from concurrent modifications by the datamart processing thread.
        Map<String, Queue<Long>> newDmMulti = new ConcurrentHashMap<>();

        boolean processingFailed = false;

        for (Entry<String, List<Long>> entry : sortedEntries) {
            String keyTopic = entry.getKey();
            List<Long> ids = entry.getValue();

            if (processingFailed) {
                if (batchId != null){
                    Map<String, Queue<Long>> retryMap = retryCache.get(batchId);
                    retryMap.computeIfAbsent(keyTopic, k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                }
                continue;
            }

            if (batchId == null) {
                logger.info(PROCESSING_IDS_LOG_MSG, ids.size(), keyTopic);
            } else {
                logger.info("Retrying {} id(s) from topic: {}, attempt #{} for batch id: {}",
                        ids.size(), keyTopic, dmProcessor.retryAttempts.getOrDefault(batchId, 0)+1, batchId);
            }

            Entity entity = getEntityByTopic(keyTopic);
            try {
                switch (entity) {
                    case PAGE:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForNBSPage, dmProcessor::checkResult);
                        break;
                    case ORGANIZATION:
                        dmDataSp = processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForOrganizationIds, dmProcessor::checkResult);
                        newDmMulti.computeIfAbsent(ORGANIZATION.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    case PROVIDER:
                        dmDataSp = processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForProviderIds, dmProcessor::checkResult);
                        newDmMulti.computeIfAbsent(PROVIDER.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    case PATIENT:
                        dmDataSp = processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForPatientIds, dmProcessor::checkResult);
                        newDmMulti.computeIfAbsent(PATIENT.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    case AUTH_USER:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForUserProfile, dmProcessor::checkResult);
                        break;
                    case D_PLACE:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForDPlace, dmProcessor::checkResult);
                        break;
                    case INVESTIGATION:
                        dmDataSp = processInvestigation(keyTopic, entity, ids, pbCache);
                        newDmMulti.computeIfAbsent(INVESTIGATION.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        processByInvFormCode(dmDataSp, keyTopic);
                        break;
                    case CONTACT:
                        dmDataSp = processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForDContactRecord, dmProcessor::checkResult);
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForFContactRecordCase, dmProcessor::checkResult,
                                "sp_f_contact_record_case_postprocessing");
                        newDmMulti.computeIfAbsent(CONTACT.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    case NOTIFICATION:
                        dmDataSp = processTopic(keyTopic, entity, ids, investigationRepository::executeStoredProcForNotificationIds, dmProcessor::checkResult);
                        newDmMulti.computeIfAbsent(NOTIFICATION.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    case CASE_MANAGEMENT:
                        processTopic(keyTopic, entity, ids, investigationRepository::executeStoredProcForCaseManagement, dmProcessor::checkResult);
                        processTopic(keyTopic, entity, ids, investigationRepository::executeStoredProcForFStdPageCase, dmProcessor::checkResult,
                                "sp_f_std_page_case_postprocessing");
                        break;
                    case INTERVIEW:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForDInterview, dmProcessor::checkResult);
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForFInterviewCase, dmProcessor::checkResult,
                                "sp_f_interview_case_postprocessing");
                        break;
                    case STATE_DEFINED_FIELD_METADATA:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForLdfDimensionalData, dmProcessor::checkResult);
                        break;
                    case LDF_DATA:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForLdfIds, dmProcessor::checkResult);
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForLdfDimensionalData, dmProcessor::checkResult);
                        break;
                    case OBSERVATION:
                        dmDataSp = processObservation(keyTopic, entity, obsCache);
                        newDmMulti.computeIfAbsent(OBSERVATION.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    case TREATMENT:
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForTreatment, dmProcessor::checkResult);
                        break;
                    case VACCINATION:
                        dmDataSp = processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForDVaccination, dmProcessor::checkResult);
                        processTopic(keyTopic, entity, ids, postProcRepository::executeStoredProcForFVaccination, dmProcessor::checkResult,
                                "sp_f_vaccination_postprocessing");
                        newDmMulti.computeIfAbsent(VACCINATION.getEntityName(), k -> new ConcurrentLinkedQueue<>()).addAll(ids);
                        break;
                    default:
                        logger.warn(UNKNOWN_TOPIC_LOG_MSG, keyTopic);
                        break;
                }
                dmData = Stream.concat(dmData.stream(), dmDataSp.stream()).distinct().toList();
                ppMsgSuccess.increment(ids.size());
            } catch (Exception e) {
                if (batchId == null) { // do not count failed retries here to avoid double counting
                    ppMsgFailure.increment(ids.size());
                }
                logger.error(errorMessage(entity.getEntityName(), listToParameterString(ids), new Exception(e.getClass().getSimpleName())));
                processingFailed = true;
                batchId = buildRetryCache(batchId, keyTopic, ids, pbCache, obsCache, e);
            }
        }

        // process METRIC_EVENT datamart since multiple datamarts depend on it
        processMetricEventDatamart(newDmMulti);
        processSummaryCases();
        dmProcessor.process(dmData);

        // merge entity IDs collections from temporary map newDmMulti into main datamart cache
        synchronized (cacheLock) {
            Map<String, Queue<Long>> dmMulti = dmCache.computeIfAbsent(MULTI_ID_DATAMART, k -> new ConcurrentHashMap<>());
            newDmMulti.forEach((key, queue) ->
                    dmMulti.computeIfAbsent(key, k -> new ConcurrentLinkedQueue<>()).addAll(queue));
        }

        return !processingFailed;
    }

    private void processCdCache(Map<String, List<String>> cdCacheSnapshot) {
        for (Entry<String, List<String>> entry : cdCacheSnapshot.entrySet()) {
            String keyTopic = entry.getKey();
            List<String> cds = entry.getValue();
            Entity entity = getEntityByTopic(keyTopic);
            logger.info(PROCESSING_IDS_LOG_MSG, cds.size(), keyTopic);

            try {
                if (Objects.requireNonNull(entity) == CONDITION) {
                    processTopic(keyTopic, entity, cds, postProcRepository::executeStoredProcForConditionCode);
                } else {
                    logger.warn(UNKNOWN_TOPIC_LOG_MSG, keyTopic);
                }
                ppMsgSuccess.increment(cds.size());
            } catch (Exception e) {
                String ids = cds.stream().distinct().collect(Collectors.joining(","));
                logger.error(errorMessage(entity.getEntityName(), ids, new Exception(e.getClass().getSimpleName())));
                ppMsgFailure.increment(cds.size());
            }
        }
    }

    private void processSummaryCases() {
        // Making cache snapshot preventing out-of-sequence ids processing
        final Set<Long> sumUids;
        final Set<Long> aggUids;

        synchronized (cacheLock) {
            sumUids = Optional.ofNullable(sumCache.get(CASE_TYPE_SUM))
                    .map(HashSet::new)
                    .orElse(new HashSet<>());
            aggUids = Optional.ofNullable(sumCache.get(CASE_TYPE_AGG))
                    .map(HashSet::new)
                    .orElse(new HashSet<>());
            sumCache.clear();
        }

        processTopic(investigationTopic, SUMMARY_REPORT_CASE, sumUids,
                investigationRepository::executeStoredProcForSummaryReportCase);

        processTopic(investigationTopic, SR100_DATAMART, sumUids,
                investigationRepository::executeStoredProcForSR100Datamart);

        processTopic(investigationTopic, AGGREGATE_REPORT_DATAMART, aggUids,
                investigationRepository::executeStoredProcForAggregateReport);
    }

    private void processByInvFormCode(List<DatamartData> dmData, String keyTopic) {

        Set<Long> pamUids = dmData.stream()
        .filter(d -> "INV_FORM_RVCT".equals(d.getInvestigationFormCd()))
        .map(DatamartData::getPublicHealthCaseUid)
        .collect(Collectors.toSet());

        if(!pamUids.isEmpty()){
            //TB
            processTopic(keyTopic, D_TB_PAM, pamUids, investigationRepository::executeStoredProcForDTbPam, dmProcessor::checkResult);
            processTopic(keyTopic, D_ADDL_RISK, pamUids, investigationRepository::executeStoredProcForDAddlRisk, dmProcessor::checkResult);
            processTopic(keyTopic, D_DISEASE_SITE, pamUids, investigationRepository::executeStoredProcForDDiseaseSite, dmProcessor::checkResult);
            processTopic(keyTopic, D_TB_HIV, pamUids, investigationRepository::executeStoredProcForDTbHiv, dmProcessor::checkResult);
            processTopic(keyTopic, D_GT_12_REAS, pamUids, investigationRepository::executeStoredProcForDGt12Reas, dmProcessor::checkResult);
            processTopic(keyTopic, D_MOVE_CNTRY, pamUids, investigationRepository::executeStoredProcForDMoveCntry, dmProcessor::checkResult);
            processTopic(keyTopic, D_MOVE_CNTY, pamUids, investigationRepository::executeStoredProcForDMoveCnty, dmProcessor::checkResult);
            processTopic(keyTopic, D_MOVE_STATE, pamUids, investigationRepository::executeStoredProcForDMoveState, dmProcessor::checkResult);
            processTopic(keyTopic, D_MOVED_WHERE, pamUids, investigationRepository::executeStoredProcForDMovedWhere, dmProcessor::checkResult);
            processTopic(keyTopic, D_HC_PROV_TY_3, pamUids, investigationRepository::executeStoredProcForDHcProvTy3, dmProcessor::checkResult);
            processTopic(keyTopic, D_OUT_OF_CNTRY, pamUids, investigationRepository::executeStoredProcForDOutOfCntry, dmProcessor::checkResult);
            processTopic(keyTopic, D_SMR_EXAM_TY, pamUids, investigationRepository::executeStoredProcForDSmrExamTy, dmProcessor::checkResult);
            processTopic(keyTopic, F_TB_PAM, pamUids, investigationRepository::executeStoredProcForFTbPam, dmProcessor::checkResult);
            processTopic(keyTopic, TB_PAM_LDF, pamUids, investigationRepository::executeStoredProcForTbPamLdf, dmProcessor::checkResult);
        }

        //VAR
        pamUids = dmData.stream()
        .filter(d -> "INV_FORM_VAR".equals(d.getInvestigationFormCd()))
        .map(DatamartData::getPublicHealthCaseUid)
        .collect(Collectors.toSet());

        if(!pamUids.isEmpty()){
            processTopic(keyTopic, D_VAR_PAM, pamUids, investigationRepository::executeStoredProcForDVarPam, dmProcessor::checkResult);
            processTopic(keyTopic, D_RASH_LOC_GEN, pamUids, investigationRepository::executeStoredProcForDRashLocGen, dmProcessor::checkResult);
            processTopic(keyTopic, D_PCR_SOURCE, pamUids, investigationRepository::executeStoredProcForDPcrSource, dmProcessor::checkResult);
            processTopic(keyTopic, F_VAR_PAM, pamUids, investigationRepository::executeStoredProcForFVarPam, dmProcessor::checkResult);
            processTopic(keyTopic, VAR_PAM_LDF, pamUids, investigationRepository::executeStoredProcForVarPamLdf, dmProcessor::checkResult);
        }
    }

    private List<DatamartData> processInvestigation(
            String keyTopic, Entity entity, List<Long> ids, Map<String, List<Long>> pbCache) {
        List<DatamartData> dmData;
        dmData = processTopic(keyTopic, entity, ids, investigationRepository::executeStoredProcForPublicHealthCaseIds, dmProcessor::checkResult);

        pbCache.forEach((tbl, uids) -> processTopic(keyTopic, CASE_ANSWERS, uids, tbl,
                investigationRepository::executeStoredProcForPageBuilder, dmProcessor::checkResult));

        processTopic(keyTopic, F_PAGE_CASE, ids, investigationRepository::executeStoredProcForFPageCase, dmProcessor::checkResult);
        processTopic(keyTopic, CASE_COUNT, ids, investigationRepository::executeStoredProcForCaseCount, dmProcessor::checkResult);
                                       
        return dmData;
    }

    private List<DatamartData> processObservation(
            String keyTopic, Entity entity, Map<String, List<Long>> obsCache) {
        final List<Long> morbIds;
        final List<Long> labIds;

        morbIds = Optional.ofNullable(obsCache.get(MORB_REPORT)).map(ArrayList::new).orElseGet(ArrayList::new);
        labIds = Optional.ofNullable(obsCache.get(LAB_REPORT)).map(ArrayList::new).orElseGet(ArrayList::new);

        List<DatamartData> dmData = new ArrayList<>();

        if (!morbIds.isEmpty()) {
            dmData = processTopic(keyTopic, entity, morbIds,
                    postProcRepository::executeStoredProcForMorbReport, dmProcessor::checkResult,
                    "sp_d_morbidity_report_postprocessing");
        }

        if (!labIds.isEmpty()) {
            processTopic(keyTopic, entity, labIds,
                    postProcRepository::executeStoredProcForLabTest, dmProcessor::checkResult,
                    "sp_d_lab_test_postprocessing");

            List<DatamartData> dmDataL = processTopic(keyTopic, entity, labIds,
                    postProcRepository::executeStoredProcForLabTestResult, dmProcessor::checkResult,
                    "sp_d_labtest_result_postprocessing");
            dmData = Stream.concat(dmData.stream(), dmDataL.stream()).distinct().toList();

            processTopic(keyTopic, entity, labIds,
                    postProcRepository::executeStoredProcForLab100Datamart, dmProcessor::checkResult,
                    "sp_lab100_datamart_postprocessing");
            processTopic(keyTopic, entity, labIds,
                    postProcRepository::executeStoredProcForLab101Datamart, dmProcessor::checkResult,
                    "sp_lab101_datamart_postprocessing");
        }
        return dmData;
    }

    private void processMetricEventDatamart(Map<String, Queue<Long>> dmMulti) {
        String invString = listToParameterString(dmMulti.get(INVESTIGATION.getEntityName()));
        String obsString = listToParameterString(dmMulti.get(OBSERVATION.getEntityName()));
        String notifString = listToParameterString(dmMulti.get(NOTIFICATION.getEntityName()));
        String ctrString = listToParameterString(dmMulti.get(CONTACT.getEntityName()));
        String vaxString = listToParameterString(dmMulti.get(VACCINATION.getEntityName()));

        int totalLengthEventMetric = invString.length() + obsString.length() + notifString.length()
                + ctrString.length() + vaxString.length();

        if (totalLengthEventMetric > 0) {
            postProcRepository.executeStoredProcForEventMetric(invString, obsString, notifString, ctrString, vaxString);
        } else {
            logger.info("No updates to EVENT_METRIC Datamart");
        }
    }

    private Long buildRetryCache(
            Long batchId, String keyTopic, List<Long> ids, Map<String, List<Long>> pbCache, Map<String, List<Long>> obsCache, Exception e) {

        //skip retrying for non-positive value
        if (maxRetries <= 0) {
            return null;
        }

        batchId = dmProcessor.getBatchId(batchId, e);

        Map<String, Queue<Long>> retryMap = retryCache.computeIfAbsent(batchId, k -> new ConcurrentHashMap<>());
        retryMap.computeIfAbsent(keyTopic, k -> new ConcurrentLinkedQueue<>()).addAll(ids);

        pbCache.forEach((tbl, queue) ->
                retryMap.computeIfAbsent("PB^" + tbl, k -> new ConcurrentLinkedQueue<>()).addAll(queue));

        obsCache.forEach((key, queue) ->
                retryMap.computeIfAbsent("OBS^" + key, k -> new ConcurrentLinkedQueue<>()).addAll(queue));

        return batchId;
    }

    /**
     * Processes cached IDs for datamarts by executing the appropriate stored procedures. This method triggers at fixed
     * intervals and handles the processing of data that needs to be loaded into specific datamarts.
     * <p>
     * Steps:
     * <ul>1. Iterate through cached IDs grouped by datamart type.</ul>
     * <ul>2. Execute the corresponding stored procedure for each datamart type.</ul>
     * <ul>3. Log the execution status for debugging and monitoring purposes.</ul>
     */
    @Scheduled(fixedDelayString = "${service.fixed-delay.datamart}")
    protected void processDatamartIds() {

        Map<String, Map<String, List<Long>>> dmCacheSnapshot;
        synchronized (cacheLock) {
            dmCacheSnapshot = new HashMap<>();
            for (Map.Entry<String, Map<String, Queue<Long>>> entry : dmCache.entrySet()) {
                Map<String, List<Long>> idMap = new HashMap<>();
                for (Map.Entry<String, Queue<Long>> inner : entry.getValue().entrySet()) {
                    idMap.put(inner.getKey(), new ArrayList<>(inner.getValue()));
                }
                dmCacheSnapshot.put(entry.getKey(), idMap);
            }
            dmCache.clear();
        }

        if (!dmCacheSnapshot.isEmpty()) {
            dmProcessor.processDmCache(dmCacheSnapshot, null);
        }
    }

    private String listToParameterString(Collection<Long> inputList) {
        return Optional.ofNullable(inputList)
                .map(list -> list.stream().map(String::valueOf).distinct().collect(Collectors.joining(",")))
                .orElse("");
    }

    @PreDestroy
    public void shutdown() {
        processCachedIds();
        processDatamartIds();
    }

    private boolean assertMatches(String value, String... vals) {
        return Arrays.asList(vals).contains(value);
    }

    /**
     * Retrieves the entity type (e.g., INVESTIGATION, NOTIFICATION, ORGANIZATION) based on the Kafka
     * topic name. This mapping is used to determine how to process the message and which stored
     * procedure to execute.
     *
     * @param topic The name of the Kafka topic (e.g., "dummy_investigation", "dummy_notification").
     * @return The corresponding entity type as an `Entity` enum value.
     *<p>
     * Example:
     * If the topic is "dummy_investigation", the method will return `Entity.INVESTIGATION`.
     *
     * @throws IllegalArgumentException If the topic does not map to a known entity type.
     */
    @NonNull
    private Entity getEntityByTopic(String topic) {
        return Arrays.stream(Entity.values())
                .filter(entity -> entity.getPriority() > 0)
                .filter(entity -> topic.endsWith(entity.getEntityName()))
                .findFirst()
                .orElse(UNKNOWN);
    }

    private void processTopic(String keyTopic, Entity entity, Collection<Long> ids, Consumer<String> repositoryMethod,
            String... names) {
        if (!ids.isEmpty()) {
            String idsString = listToParameterString(ids);
            String spName = names.length > 0 ? names[0] : entity.getStoredProcedure();
            prepareAndLog(keyTopic, idsString, entity.getEntityName(), spName);
            repositoryMethod.accept(idsString);
            completeLog(spName);
        }
    }

    private void processTopic(String keyTopic, Entity entity, Collection<String> cds, Consumer<String> repositoryMethod) {
        String cdString = cds.stream().distinct().collect(Collectors.joining(","));
        String spName = entity.getStoredProcedure();
        prepareAndLog(keyTopic, cdString, entity.getEntityName(), spName);
        repositoryMethod.accept(cdString);
        completeLog(spName);
    }

    private <T> List<T> processTopic(String keyTopic, Entity entity, Collection<Long> ids,
                                     Function<String, List<T>> repositoryMethod, Consumer<List<T>> checkResult,
                                     String... names) {
        String spName = names.length > 0 ? names[0] : entity.getStoredProcedure();
        String idString = listToParameterString(ids);
        prepareAndLog(keyTopic, idString, entity.getEntityName(), spName);
        List<T> result = repositoryMethod.apply(idString);
        checkResult.accept(result);
        completeLog(spName);
        return result;
    }

    private <T> void processTopic(String keyTopic, Entity entity, Collection<Long> ids, String vals,
                                  BiFunction<String, String, List<T>> repositoryMethod, Consumer<List<T>> checkResult) {
        String name = entity.getEntityName();
        name = logger.isInfoEnabled() ? StringUtils.capitalize(name) : name;
        String idString = listToParameterString(ids);
        logger.info("Processing {} for topic: {}. Calling stored proc: {} '{}', '{}'", name, keyTopic,
                entity.getStoredProcedure(), idString, vals);
        List<T> result = repositoryMethod.apply(idString, vals);
        checkResult.accept(result);
        completeLog(entity.getStoredProcedure());
    }

    private void prepareAndLog(String keyTopic, String idString, String name, String spName) {
        name = logger.isInfoEnabled() ? StringUtils.capitalize(name) : name;
        logger.info("Processing {} for topic: {}. Calling stored proc: {} '{}'", name, keyTopic,
                spName, idString);
    }

    private void completeLog(String sp) {
        logger.info(SP_EXECUTION_COMPLETED, sp);
    }
}