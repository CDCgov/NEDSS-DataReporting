package gov.cdc.nbs.report.pipeline.postprocessing.service;

import static gov.cdc.nbs.report.pipeline.postprocessing.service.Entity.*;
import static gov.cdc.nbs.report.pipeline.util.UtilHelper.errorMessage;

import com.google.common.base.Strings;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.InvestigationRepository;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.PostProcRepository;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.model.BackfillData;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.model.DatamartData;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.model.dto.Datamart;
import gov.cdc.nbs.report.pipeline.postprocessing.repository.model.dto.DatamartKey;
import gov.cdc.nbs.report.pipeline.util.DataProcessingException;
import gov.cdc.nbs.report.pipeline.util.json.CustomJsonGeneratorImpl;
import gov.cdc.nbs.report.pipeline.util.metrics.CustomMetrics;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Timer;
import jakarta.annotation.PostConstruct;
import java.util.*;
import java.util.concurrent.*;
import java.util.function.BiFunction;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.function.UnaryOperator;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.modelmapper.ModelMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.scheduling.concurrent.CustomizableThreadFactory;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Setter
public class ProcessDatamartData {
  private static final Logger logger = LoggerFactory.getLogger(ProcessDatamartData.class);

  // unique per instance, randomly assigned once
  static final int INSTANCE_ID =
      new Random(System.identityHashCode(ProcessDatamartData.class))
          .nextInt(1 << 10); // 10-bit random ID

  private static int nProc = Runtime.getRuntime().availableProcessors();
  private final ExecutorService dynDmExecutor =
      Executors.newFixedThreadPool(nProc, new CustomizableThreadFactory("dynDm-"));

  @Qualifier("postProcessingKafkaTemplate")
  private final KafkaTemplate<String, String> kafkaTemplate;

  private final PostProcRepository procRepository;

  @Qualifier("ppInvestigationRepository")
  private final InvestigationRepository invRepository;

  private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();
  private final ModelMapper modelMapper = new ModelMapper();
  private final Object cacheLock = new Object();

  // set of caches for retrying failed datamarts/IDs and tracking retry attempts
  final Map<Long, Map<String, Map<String, Queue<Long>>>> retryCache = new ConcurrentHashMap<>();
  final Map<Long, String> errorMap = new ConcurrentHashMap<>();
  final Map<Long, Integer> retryAttempts = new ConcurrentHashMap<>();
  final Map<Long, Integer> backfillAttempts = new ConcurrentHashMap<>();

  @Value("${service.max-retries}")
  private int maxRetries;

  static final String MULTI_ID_DATAMART = "MultiId_Datamart";
  static final String SP_EXECUTION_COMPLETED = "Stored proc execution completed: {}";
  static final String PROCESSING_MESSAGE_TOPIC_LOG_MSG =
      "Processing {} message topic. Calling stored proc: {} '{}'";
  static final String PROCESSING_MESSAGE_TOPIC_LOG_MSG_2 =
      "Processing {} message topic. Calling stored proc: {} '{}', '{}'";

  static final String STATUS_READY = "READY";
  static final String STATUS_COMPLETE = "COMPLETE";
  static final String STATUS_SUSPENDED = "SUSPENDED";

  static final String SERVICE_NAME = "post-process-reporting";

  @Value("${spring.kafka.topics.nbs.datamart}")
  public String datamartTopic;

  private final CustomMetrics metrics;

  private Counter ppDmSuccess;
  private Counter ppDmFailure;

  Timer processTimer;

  @PostConstruct
  void initMetrics() {
    String[] tags = {"service", SERVICE_NAME};

    ppDmSuccess = metrics.counter("post_dm_success", tags);
    ppDmFailure = metrics.counter("post_dm_failure", tags);

    processTimer = metrics.timer("post_dm_batch_processing_seconds", tags);
  }

  public void process(List<DatamartData> data) {
    if (Objects.nonNull(data) && !data.isEmpty()) {
      data = reduce(data);
      try {
        for (DatamartData datamartData : data) {

          if (Strings.isNullOrEmpty(datamartData.getDatamart())
              || Objects.isNull(datamartData.getPatientUid())) {
            continue; // skipping now for empty datamart or unprocessed patients
          }

          Datamart dmart = modelMapper.map(datamartData, Datamart.class);
          DatamartKey dmKey = new DatamartKey();
          dmKey.setEntityUid(datamartData.getPublicHealthCaseUid());
          String jsonKey = jsonGenerator.generateStringJson(dmKey);
          String jsonMessage = jsonGenerator.generateStringJson(dmart);

          kafkaTemplate.send(datamartTopic, jsonKey, jsonMessage);
          logger.info(
              "Datamart data: uid={}, datamart={} sent to {} topic",
              dmart.getPublicHealthCaseUid(),
              dmart.getDatamart(),
              datamartTopic);
        }
      } catch (Exception e) {
        String msg = "Error processing Datamart JSON array from datamart data: " + e.getMessage();
        throw new DataProcessingException(msg, e);
      }
    }
  }

  private List<DatamartData> reduce(List<DatamartData> dmData) {
    final String hepDm = HEPATITIS_DATAMART.getEntityName();
    List<Long> hepUidsAlreadyInDmData =
        dmData.stream()
            .filter(Objects::nonNull)
            .filter(d -> d.getDatamart().startsWith(hepDm)) // excludes
            .map(DatamartData::getPublicHealthCaseUid)
            .toList();

    return dmData.stream()
        .filter(Objects::nonNull)
        .filter(
            d -> {
              boolean isCaseLab = CASE_LAB_DATAMART.getEntityName().equals(d.getDatamart());
              boolean hasHepAlready = hepUidsAlreadyInDmData.contains(d.getPublicHealthCaseUid());
              // If it's Case_Lab_Datamart AND we already have that UID in Hepatitis_Datamart ->
              // exclude
              return !(isCaseLab && hasHepAlready);
            })
        .toList();
  }

  protected boolean processDmCache(Map<String, Map<String, List<Long>>> dmCache, Long batchId) {
    List<Long> ldfUids = new ArrayList<>();
    // investigation uids whose CASE_LAB_DATAMART was (re)built in this batch; INV_SUMM_DATAMART
    // must be refreshed for them afterwards (see processMultiIdDatamart call below).
    List<Long> caseLabInvUids = new ArrayList<>();
    BatchProcessingState state = new BatchProcessingState(batchId);

    Timer.Sample sample = metrics.startSample();

    for (Map.Entry<String, Map<String, List<Long>>> entry : dmCache.entrySet()) {
      String dmKey = entry.getKey();

      if (MULTI_ID_DATAMART.equals(dmKey)) {
        continue;
      }

      Map<String, List<Long>> dmValues = entry.getValue();

      List<Long> uids = getUids(dmValues, INVESTIGATION);

      if (state.isRetry) {
        logger.info(
            "Retrying {} id(s) from datamart topic: {}, attempt #{} for batch id: {}",
            uids.size(),
            dmKey,
            retryAttempts.getOrDefault(state.getBatchId(), 0) + 1,
            state.getBatchId());
      }

      try {
        processDatamart(dmKey, dmValues, ldfUids, caseLabInvUids);
        incrementIf(ppDmSuccess, !state.isRetry);
      } catch (Exception e) {
        incrementIf(ppDmFailure, !state.isRetry);
        logger.error(
            errorMessage(
                dmKey, listToParameterString(uids), new Exception(e.getClass().getSimpleName())));
        state.registerFailure(dmKey, dmValues, e);
      }
    }

    processLdfVaccinePreventDm(state, ldfUids);

    // INV_SUMM_DATAMART (a multi-id datamart) derives its lab columns (LABORATORY_INFORMATION,
    // EVENT_DATE, EVENT_DATE_TYPE, EARLIEST_SPECIMEN_COLLECT_DATE) from CASE_LAB_DATAMART, so it
    // must be built after CASE_LAB_DATAMART. Within a batch that ordering already holds
    // because multi-id datamarts are processed here, last.
    // However, there is a cross-batch race: when an investigation's multi-id trigger
    // is cached synchronously while its Case_Lab_Datamart trigger
    // round-trips through Kafka, so the two can land in different batches and INV_SUMM can run
    // first, leaving those columns NULL. Passing the CASE_LAB investigation uids here guarantees
    // INV_SUMM is built in the same batch as (and after) CASE_LAB_DATAMART.
    // https://cdc-nbs.atlassian.net/browse/APP-775
    Map<String, List<Long>> multiId = dmCache.get(MULTI_ID_DATAMART);
    if (multiId != null || !caseLabInvUids.isEmpty()) {
      processMultiIdDatamart(state, multiId, caseLabInvUids);
    }

    metrics.stopSample(sample, processTimer);
    return !state.hasFailed();
  }

  private void incrementIf(Counter cnt, boolean notRetry) {
    if (notRetry) {
      cnt.increment();
    }
  }

  /**
   * Processes a datamart entry and calls the appropriate stored procedures.
   *
   * <p>The {@code dmKey} can include a primary datamart (e.g., {@code HEPATITIS_DATAMART}) and an
   * optional LDF (Legacy Data Form) type separated by a comma. The {@code idMap} pairs entity names
   * with the IDs to be processed.
   *
   * @param dmKey the datamart key, optionally with an LDF type after a comma
   * @param idMap a map of entity names to lists of IDs
   * @param ldfUids a list to store case IDs for LDF-related datamarts
   * @param caseLabInvUids a list to collect investigation IDs whose CASE_LAB_DATAMART is processed,
   *     so INV_SUMM_DATAMART can be refreshed for them afterwards
   */
  private void processDatamart(
      String dmKey, Map<String, List<Long>> idMap, List<Long> ldfUids, List<Long> caseLabInvUids) {
    List<Long> uids = getUids(idMap, INVESTIGATION);
    List<Long> patUids = getUids(idMap, PATIENT);
    List<Long> obsUids = getUids(idMap, OBSERVATION);

    // for complex value (e.g. "GENERIC_CASE,LDF_GENERIC") the key should be parsed
    String[] dmTypes = dmKey.split(",");
    String dmType = dmTypes[0];
    String ldfType = dmTypes.length > 1 ? dmTypes[1] : "UNKNOWN";

    if (ldfType.equalsIgnoreCase(LDF_VACCINE_PREVENT_DISEASES.getEntityName())) {
      ldfUids.addAll(uids);
    }

    // list of phc uids concatenated together with ',' to be passed as input for the stored procs
    // for COVID_VAC_DATAMART it actually contains vaccination uids
    String cases = listToParameterString(uids);

    // make sure the entity names for datamart enum values follows the same naming
    // as the enum itself
    switch (Entity.valueOf(dmType.toUpperCase())) {
      case HEPATITIS_DATAMART:
        executeDmProc(
            CASE_LAB_DATAMART,
            invRepository::executeStoredProcForCaseLabDatamart,
            cases,
            this::checkResult);
        caseLabInvUids.addAll(uids);
        executeDmProc(
            HEPATITIS_DATAMART,
            invRepository::executeStoredProcForHepDatamart,
            cases,
            this::checkResult);
        break;
      case STD_HIV_DATAMART:
        executeDmProc(
            STD_HIV_DATAMART,
            invRepository::executeStoredProcForStdHIVDatamart,
            cases,
            this::checkResult);
        break;
      case GENERIC_CASE:
        executeDmProc(
            GENERIC_CASE,
            invRepository::executeStoredProcForGenericCaseDatamart,
            cases,
            this::checkResult);
        processLdfLegacy(ldfType, cases);
        break;
      case CRS_CASE:
        executeDmProc(
            CRS_CASE, invRepository::executeStoredProcForCRSCaseDatamart, cases, this::checkResult);
        break;
      case RUBELLA_CASE:
        executeDmProc(
            RUBELLA_CASE,
            invRepository::executeStoredProcForRubellaCaseDatamart,
            cases,
            this::checkResult);
        break;
      case MEASLES_CASE:
        executeDmProc(
            MEASLES_CASE,
            invRepository::executeStoredProcForMeaslesCaseDatamart,
            cases,
            this::checkResult);
        break;
      case CASE_LAB_DATAMART:
        executeDmProc(
            CASE_LAB_DATAMART,
            invRepository::executeStoredProcForCaseLabDatamart,
            cases,
            this::checkResult);
        caseLabInvUids.addAll(uids);
        break;
      case BMIRD_CASE:
        executeDmProc(
            BMIRD_CASE,
            invRepository::executeStoredProcForBmirdCaseDatamart,
            cases,
            this::checkResult);
        executeDmProc(
            BMIRD_STREP_PNEUMO_DATAMART,
            invRepository::executeStoredProcForBmirdStrepPneumoDatamart,
            cases,
            this::checkResult);
        processLdfLegacy(ldfType, cases);
        break;
      case HEPATITIS_CASE:
        executeDmProc(
            HEPATITIS_CASE,
            invRepository::executeStoredProcForHepatitisCaseDatamart,
            cases,
            this::checkResult);
        executeDmProc(HEP100, invRepository::executeStoredProcForHep100, cases, this::checkResult);
        processLdfLegacy(ldfType, cases);
        break;
      case PERTUSSIS_CASE:
        executeDmProc(
            PERTUSSIS_CASE,
            invRepository::executeStoredProcForPertussisCaseDatamart,
            cases,
            this::checkResult);
        break;
      case TB_DATAMART:
        executeDmProc(
            TB_DATAMART, invRepository::executeStoredProcForTbDatamart, cases, this::checkResult);

        executeDmProc(
            TB_HIV_DATAMART,
            invRepository::executeStoredProcForTbHivDatamart,
            cases,
            this::checkResult);
        break;
      case VAR_DATAMART:
        executeDmProc(
            VAR_DATAMART, invRepository::executeStoredProcForVarDatamart, cases, this::checkResult);
        break;
      case COVID_CASE_DATAMART:
        executeDmProc(
            COVID_CASE_DATAMART,
            invRepository::executeStoredProcForCovidCaseDatamart,
            cases,
            this::checkResult);
        break;
      case COVID_CONTACT_DATAMART:
        executeDmProc(
            COVID_CONTACT_DATAMART,
            invRepository::executeStoredProcForCovidContactDatamart,
            cases,
            this::checkResult);
        break;
      case COVID_VACCINATION_DATAMART:
        String pats = listToParameterString(patUids);
        executeDmProc(
            COVID_VACCINATION_DATAMART,
            invRepository::executeStoredProcForCovidVacDatamart,
            cases,
            pats,
            this::checkResult);
        break;
      case COVID_LAB_DATAMART:
        String labs = listToParameterString(obsUids);
        executeDmProc(
            COVID_LAB_DATAMART,
            invRepository::executeStoredProcForCovidLabDatamart,
            labs,
            this::checkResult);
        executeDmProc(
            COVID_LAB_CELR_DATAMART,
            invRepository::executeStoredProcForCovidLabCelrDatamart,
            labs,
            this::checkResult);
        break;
      default:
        logger.info("No associated datamart processing logic found for the key: {} ", dmType);
    }
  }

  private void processLdfVaccinePreventDm(BatchProcessingState state, List<Long> ldfUids) {
    if (!ldfUids.isEmpty()) {

      String cases = listToParameterString(ldfUids);
      try {
        executeDmProc(
            LDF_VACCINE_PREVENT_DISEASES,
            invRepository::executeStoredProcForLdfVacPreventDiseasesDatamart,
            cases,
            this::checkResult);
        incrementIf(ppDmSuccess, !state.isRetry);
      } catch (Exception e) {
        incrementIf(ppDmFailure, !state.isRetry);
        String ldfType = LDF_VACCINE_PREVENT_DISEASES.getEntityName();
        String dmKey = "LDF," + ldfType;

        logger.error(errorMessage(ldfType, cases, new Exception(e.getClass().getSimpleName())));
        state.registerFailure(
            dmKey, Collections.singletonMap(INVESTIGATION.getEntityName(), ldfUids), e);
      }
    }
  }

  private void processLdfLegacy(String ldfType, String cases) {
    switch (Entity.valueOf(ldfType.toUpperCase())) {
      case LDF_GENERIC:
        executeDmProc(
            LDF_GENERIC,
            invRepository::executeStoredProcForLdfGenericDatamart,
            cases,
            this::checkResult);
        break;
      case LDF_FOODBORNE:
        executeDmProc(
            LDF_FOODBORNE,
            invRepository::executeStoredProcForLdfFoodBorneDatamart,
            cases,
            this::checkResult);
        break;
      case LDF_TETANUS:
        // to test this, Tetanus must be added as a legacy page and
        // [dbo].nrt_datamart_metadata table must be updated adding TETANUS
        executeDmProc(
            LDF_TETANUS,
            invRepository::executeStoredProcForLdfTetanusDatamart,
            cases,
            this::checkResult);
        break;
      case LDF_MUMPS:
        executeDmProc(
            LDF_MUMPS,
            invRepository::executeStoredProcForLdfMumpsDatamart,
            cases,
            this::checkResult);
        break;
      case LDF_BMIRD:
        executeDmProc(
            LDF_BMIRD,
            invRepository::executeStoredProcForLdfBmirdDatamart,
            cases,
            this::checkResult);
        break;
      case LDF_HEPATITIS:
        executeDmProc(
            LDF_HEPATITIS,
            invRepository::executeStoredProcForLdfHepatitisDatamart,
            cases,
            this::checkResult);
        break;
      default:
        break;
    }
  }

  /**
   * Processes cached IDs for multi-ID datamarts by executing the appropriate stored procedures.
   *
   * @param state the batch processing state used for retry/failure bookkeeping
   * @param dmMulti the multi-id datamart id map for this batch, or {@code null} when the batch only
   *     carries CASE_LAB_DATAMART triggers (see {@code caseLabInvUids})
   * @param caseLabInvUids investigation uids whose CASE_LAB_DATAMART was (re)built in this batch;
   *     INV_SUMM_DATAMART is refreshed for them in addition to any multi-id investigation trigger,
   *     so its lab-derived columns are not left out of sync. These uids are intentionally NOT fed
   *     to the morbidity report datamart, which does not depend on CASE_LAB_DATAMART.
   */
  private void processMultiIdDatamart(
      BatchProcessingState state, Map<String, List<Long>> dmMulti, List<Long> caseLabInvUids) {
    Map<String, List<Long>> multi = (dmMulti == null) ? Map.of() : dmMulti;

    String invString = listToParameterString(multi.get(INVESTIGATION.getEntityName()));
    String obsString = listToParameterString(multi.get(OBSERVATION.getEntityName()));
    String notifString = listToParameterString(multi.get(NOTIFICATION.getEntityName()));
    String patString = listToParameterString(multi.get(PATIENT.getEntityName()));
    String provString = listToParameterString(multi.get(PROVIDER.getEntityName()));
    String orgString = listToParameterString(multi.get(ORGANIZATION.getEntityName()));

    // INV_SUMM additionally covers investigations whose CASE_LAB_DATAMART was rebuilt this batch.
    List<Long> invSummaryUids =
        new ArrayList<>(
            Optional.ofNullable(multi.get(INVESTIGATION.getEntityName())).orElseGet(List::of));
    invSummaryUids.addAll(caseLabInvUids);
    String invSummaryInvString = listToParameterString(invSummaryUids);

    int totalLengthInvSummary =
        invSummaryInvString.length() + notifString.length() + obsString.length();
    int totalLengthMorbReportDM =
        obsString.length()
            + patString.length()
            + provString.length()
            + orgString.length()
            + invString.length();

    try {
      if (totalLengthInvSummary > 0) {
        // reusing the same DTO class for Dynamic Marts
        logger.info(
            "Executing stored proc: sp_inv_summary_datamart_postprocessing '{}', '{}', '{}'",
            invSummaryInvString,
            notifString,
            obsString);
        List<DatamartData> dmDataList =
            procRepository.executeStoredProcForInvSummaryDatamart(
                invSummaryInvString, notifString, obsString);
        logExecutionCompleted("sp_inv_summary_datamart_postprocessing");
        processDynDatamart(state, dmDataList);
        incrementIf(ppDmSuccess, !state.isRetry);
      } else {
        logger.info("No updates to INV_SUMMARY Datamart");
      }

      if (totalLengthMorbReportDM > 0) {
        logger.info(
            "Executing stored proc: sp_morbidity_report_datamart_postprocessing '{}', '{}', '{}',"
                + " '{}', '{}'",
            obsString,
            patString,
            provString,
            orgString,
            invString);
        procRepository.executeStoredProcForMorbidityReportDatamart(
            obsString, patString, provString, orgString, invString);
        logExecutionCompleted("sp_morbidity_report_datamart_postprocessing");
        incrementIf(ppDmSuccess, !state.isRetry);
      } else {
        logger.info("No updates to MORBIDITY_REPORT_DATAMART");
      }
    } catch (Exception e) {
      incrementIf(ppDmFailure, !state.isRetry);
      logger.error(
          errorMessage(
              MULTI_ID_DATAMART, invSummaryInvString, new Exception(e.getClass().getSimpleName())));
      // Preserve any multi-id ids for retry and ensure the CASE_LAB-driven INV_SUMM uids are
      // retried too (dmMulti may be null when the batch only carried CASE_LAB_DATAMART triggers).
      Map<String, List<Long>> retryMap = new HashMap<>(multi);
      retryMap.put(INVESTIGATION.getEntityName(), invSummaryUids);
      state.registerFailure(MULTI_ID_DATAMART, retryMap, e);
    }
  }

  private void processDynDatamart(BatchProcessingState state, List<DatamartData> dmDataList) {
    if (!dmDataList.isEmpty()) {
      Map<String, List<Long>> datamartPhcIdMap =
          dmDataList.stream()
              .collect(
                  Collectors.groupingBy(
                      DatamartData::getDatamart,
                      Collectors.mapping(
                          DatamartData::getPublicHealthCaseUid, Collectors.toList())));

      List<CompletableFuture<Void>> futures = new ArrayList<>();
      datamartPhcIdMap.forEach(
          (datamart, phcIds) -> {
            String phcIdsString =
                phcIds.stream().map(String::valueOf).collect(Collectors.joining(","));
            futures.add(
                CompletableFuture.runAsync(
                    () -> {
                      logger.info(
                          "Executing stored proc: sp_dyn_datamart_postprocessing '{}', '{}'",
                          datamart,
                          phcIdsString);
                      try {
                        procRepository.executeStoredProcForDynDatamart(datamart, phcIdsString);
                        logExecutionCompleted("sp_dyn_datamart_postprocessing");
                        incrementIf(ppDmSuccess, !state.isRetry);
                      } catch (Exception e) {
                        incrementIf(ppDmFailure, !state.isRetry);
                        logger.error("Error processing dynamic datamart: {}", datamart, e);
                        state.registerFailure(
                            datamart,
                            Collections.singletonMap(INVESTIGATION.getEntityName(), phcIds),
                            e);
                      }
                    },
                    dynDmExecutor));
          });

      // Wait for all async tasks to complete before returning
      CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();
    }
  }

  void processMetricEventDatamart(Map<String, Queue<Long>> dmMulti) {
    String invString = listToParameterString(dmMulti.get(INVESTIGATION.getEntityName()));
    String obsString = listToParameterString(dmMulti.get(OBSERVATION.getEntityName()));
    String notifString = listToParameterString(dmMulti.get(NOTIFICATION.getEntityName()));
    String ctrString = listToParameterString(dmMulti.get(CONTACT.getEntityName()));
    String vaxString = listToParameterString(dmMulti.get(VACCINATION.getEntityName()));

    int totalLengthEventMetric =
        invString.length()
            + obsString.length()
            + notifString.length()
            + ctrString.length()
            + vaxString.length();

    if (totalLengthEventMetric > 0) {
      Timer.Sample sample = metrics.startSample();
      logger.info(
          "Executing stored proc: sp_event_metric_datamart_postprocessing '{}', '{}', '{}', '{}',"
              + " '{}'",
          invString,
          obsString,
          notifString,
          ctrString,
          vaxString);
      procRepository.executeStoredProcForEventMetric(
          invString, obsString, notifString, ctrString, vaxString);
      logExecutionCompleted("sp_event_metric_datamart_postprocessing");
      incrementIf(ppDmSuccess, true);
      metrics.stopSample(sample, processTimer);
    }
  }

  /**
   * Scheduled task to reprocess failed datamarts by iterating through retry cache and invoking
   * {@link #processDmCache(Map, Long)} with snapshots of the cached IDs.
   *
   * <ul>
   *   1. Updates backfill records, manages retry attempts
   * </ul>
   *
   * <ul>
   *   2. Clear caches on success
   * </ul>
   *
   * <ul>
   *   3. Persists remaining IDs when the maximum retry limit is reached
   * </ul>
   */
  @Scheduled(fixedDelayString = "${service.fixed-delay.datamart}")
  protected void processRetryCache() {

    for (Map.Entry<Long, Map<String, Map<String, Queue<Long>>>> retryEntry :
        retryCache.entrySet()) {

      Long batchId = retryEntry.getKey();

      // Making a cache snapshot preventing out-of-sequence ids processing
      // creates a deep copy of cache into snapshot
      final Map<String, Map<String, List<Long>>> retryCacheSnapshot;

      synchronized (cacheLock) {
        retryCacheSnapshot =
            retryEntry.getValue().entrySet().stream()
                .collect(
                    Collectors.toMap(
                        Map.Entry::getKey,
                        e ->
                            e.getValue().entrySet().stream()
                                .collect(
                                    Collectors.toMap(
                                        Map.Entry::getKey,
                                        idEntry -> new ArrayList<>(idEntry.getValue())))));
        retryCache.remove(batchId);
      }

      boolean processed = processDmCache(retryCacheSnapshot, batchId);

      // update backfill batch record(s) if exists
      if (updateBackfills(batchId, processed)) {
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
          logger.info(
              "Reached max retries for batch id: {}. Skipping further processing.", batchId);
          retryAttempts.remove(batchId);
          retryCache.remove(batchId);

          processBackfills(retryCacheSnapshot, batchId);
          errorMap.remove(batchId);
        }
      }
    }
  }

  protected long nextBatchId(Long batchId, Exception e) {
    if (batchId == null) {
      batchId = (System.currentTimeMillis() << 10) | INSTANCE_ID;
      retryAttempts.put(batchId, 0);
    } else {
      retryAttempts.merge(batchId, 1, Integer::sum);
    }

    Throwable cause = e;
    while (cause.getCause() != null) {
      cause = cause.getCause(); // unwrap nested exceptions
    }
    String errorMsg = cause.getMessage();
    errorMap.put(batchId, errorMsg);

    return batchId;
  }

  /**
   * Persists failed entities for backfill processing into the database.
   *
   * <p>Applies nameOp to each cache key and invokes the backfill stored procedure with entity name,
   * ID list, batchId, error, status, and retry count.
   *
   * @param cache map of entity names to failed record IDs
   * @param nameOp transforms the cache key into the database-specific entity name
   * @param batchId unique batch identifier for this backfill run
   */
  void processBackfills(Map<String, List<Long>> cache, UnaryOperator<String> nameOp, Long batchId) {

    for (Map.Entry<String, List<Long>> entry : cache.entrySet()) {
      procRepository.executeStoredProcForBackfill(
          nameOp.apply(entry.getKey()),
          listToParameterString(entry.getValue()),
          batchId,
          errorMap.get(batchId),
          STATUS_READY,
          backfillAttempts.getOrDefault(batchId, 0));
    }
  }

  /**
   * Persists failed datamarts for backfill processing into the database.
   *
   * <p>Invokes the backfill stored procedure with datamart name, ID list, batchId, error, status,
   * and retry count.
   *
   * @param cache map of datamart names to failed record IDs
   * @param batchId unique batch identifier for this backfill run
   */
  void processBackfills(Map<String, Map<String, List<Long>>> cache, Long batchId) {
    for (Map.Entry<String, Map<String, List<Long>>> entry : cache.entrySet()) {
      String dmName = "DM^" + entry.getKey();
      String ids =
          entry.getValue().entrySet().stream()
              .filter(idEntry -> !idEntry.getValue().isEmpty())
              .map(idEntry -> idEntry.getKey() + ":" + listToParameterString(idEntry.getValue()))
              .collect(Collectors.joining(" "));
      procRepository.executeStoredProcForBackfill(
          dmName,
          ids.trim(),
          batchId,
          errorMap.get(batchId),
          STATUS_READY,
          backfillAttempts.getOrDefault(batchId, 0));
    }
  }

  boolean updateBackfills(Long batchId, boolean processed) {
    if (backfillAttempts.containsKey(batchId)) {
      retryAttempts.remove(batchId);

      String status = processed ? STATUS_COMPLETE : STATUS_READY;
      int bfAttempt = backfillAttempts.get(batchId) + 1;
      if (bfAttempt >= maxRetries) {
        logger.info(
            "Reached max backfill retries for batch id: {}. Suspend further processing.", batchId);
        status = STATUS_SUSPENDED;
        bfAttempt = 0;
      }

      procRepository.executeStoredProcForBackfill(
          null, null, batchId, errorMap.get(batchId), status, bfAttempt);

      backfillAttempts.remove(batchId);
      errorMap.remove(batchId);
      return true;
    }
    return false;
  }

  void updateRetryCache(Long batchId, BackfillData bfd) {
    backfillAttempts.put(batchId, bfd.getRetryCount());
    retryAttempts.put(batchId, bfd.getRetryCount());
    errorMap.put(batchId, bfd.getErrDescription());

    String dmKey = bfd.getEntity().substring("DM^".length());
    Map<String, List<Long>> idMap =
        Arrays.stream(bfd.getRecordUidList().split("\\s+"))
            .map(token -> token.split(":", 2))
            .collect(
                Collectors.toMap(
                    parts -> parts[0],
                    parts -> Arrays.stream(parts[1].split(",")).map(Long::valueOf).toList()));
    BatchProcessingState state = new BatchProcessingState(batchId);
    state.updateRetryCache(dmKey, idMap);
  }

  private <T> void executeDmProc(
      Entity dmEntity,
      Function<String, List<T>> repositoryMethod,
      String ids,
      Consumer<List<T>> checkResult) {
    if (!ids.isEmpty()) {
      logger.info(
          PROCESSING_MESSAGE_TOPIC_LOG_MSG,
          dmEntity.getEntityName(),
          dmEntity.getStoredProcedure(),
          ids);
      List<T> result = repositoryMethod.apply(ids);
      checkResult.accept(result);
      logExecutionCompleted(dmEntity.getStoredProcedure());
    }
  }

  private <T> void executeDmProc(
      Entity dmEntity,
      BiFunction<String, String, List<T>> repositoryMethod,
      String ids,
      String pids,
      Consumer<List<T>> checkResult) {
    if (!ids.isEmpty() && !pids.isEmpty()) {
      logger.info(
          PROCESSING_MESSAGE_TOPIC_LOG_MSG_2,
          dmEntity.getEntityName(),
          dmEntity.getStoredProcedure(),
          ids,
          pids);
      List<T> result = repositoryMethod.apply(ids, pids);
      checkResult.accept(result);
      logExecutionCompleted(dmEntity.getStoredProcedure());
    }
  }

  private void logExecutionCompleted(String spName) {
    logger.info(SP_EXECUTION_COMPLETED, spName);
  }

  private List<Long> getUids(Map<String, List<Long>> dmValues, Entity entity) {
    return Optional.ofNullable(dmValues.get(entity.getEntityName()))
        .map(ArrayList::new)
        .orElseGet(ArrayList::new);
  }

  private String listToParameterString(Collection<Long> inputList) {
    return Optional.ofNullable(inputList)
        .map(list -> list.stream().distinct().map(String::valueOf).collect(Collectors.joining(",")))
        .orElse("");
  }

  public void checkResult(List<DatamartData> dmData) throws DataProcessingException {
    if (!dmData.isEmpty()) {
      DatamartData dme = dmData.getFirst();
      if ("Error".equals(dme.getDatamart())) {
        throw new DataProcessingException(dme.getStoredProcedure());
      }
    }
  }

  private class BatchProcessingState {
    // final because this never changes after initialization
    final boolean isRetry;

    // volatile ensures threads reading these outside the sync block see the latest values
    // immediately
    private volatile Long batchId;
    private volatile boolean failed = false;

    // No volatile needed; only accessed inside the synchronized block
    private boolean retryCountIncremented = false;

    BatchProcessingState(Long batchId) {
      this.batchId = batchId;
      this.isRetry = (batchId != null);
    }

    // synchronized ensures only one thread can evaluate and update the state at a time
    synchronized void registerFailure(String dmKey, Map<String, List<Long>> idMap, Exception e) {
      this.failed = true;

      if (this.batchId == null) {
        // The first thread to fail gets here, generates the ID, and locks it in for the rest
        this.buildRetryCache(dmKey, idMap, e);
        this.retryCountIncremented = true;
      } else {
        if (this.isRetry && !this.retryCountIncremented) {
          this.buildRetryCache(dmKey, idMap, e);
          this.retryCountIncremented = true;
        } else {
          // Subsequent threads see the initialized batchId and safely append to it
          this.updateRetryCache(dmKey, idMap);

          Throwable cause = e;
          while (cause.getCause() != null) {
            cause = cause.getCause();
          }
          // errorMap is a ConcurrentHashMap, so this is safe
          errorMap.put(this.batchId, cause.getMessage());
        }
      }
    }

    private void buildRetryCache(String dmKey, Map<String, List<Long>> idMap, Exception e) {
      // skip retrying for non-positive value
      if (maxRetries > 0) {
        this.batchId = nextBatchId(this.batchId, e);
        this.updateRetryCache(dmKey, idMap);
      }
    }

    private void updateRetryCache(String dmKey, Map<String, List<Long>> idMap) {
      Map<String, Queue<Long>> dmMap =
          retryCache
              .computeIfAbsent(batchId, k -> new ConcurrentHashMap<>())
              .computeIfAbsent(dmKey, k -> new ConcurrentHashMap<>());
      idMap.forEach(
          (key, value) ->
              dmMap.computeIfAbsent(key, k -> new ConcurrentLinkedQueue<>()).addAll(value));
    }

    public boolean hasFailed() {
      return failed;
    }

    public Long getBatchId() {
      return batchId;
    }
  }
}
