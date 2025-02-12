package gov.cdc.etldatapipeline.investigation.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.investigation.repository.model.dto.*;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.*;
import gov.cdc.etldatapipeline.investigation.repository.InvestigationRepository;
import gov.cdc.etldatapipeline.investigation.repository.model.reporting.InterviewReporting;
import lombok.Setter;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
@Setter
public class ProcessInvestigationDataUtil {
    private static final Logger logger = LoggerFactory.getLogger(ProcessInvestigationDataUtil.class);
    private static final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    @Value("${spring.kafka.output.topic-name-confirmation}")
    public String investigationConfirmationOutputTopicName;

    @Value("${spring.kafka.output.topic-name-observation}")
    public String investigationObservationOutputTopicName;

    @Value("${spring.kafka.output.topic-name-notifications}")
    public String investigationNotificationsOutputTopicName;

    @Value("${spring.kafka.output.topic-name-page-case-answer}")
    public String pageCaseAnswerOutputTopicName;

    @Value("${spring.kafka.output.topic-name-case-management}")
    public String investigationCaseManagementTopicName;

    @Value("${spring.kafka.output.topic-name-interview}")
    private String interviewOutputTopicName;

    @Value("${spring.kafka.output.topic-name-interview-answer}")
    private String interviewAnswerOutputTopicName;

    @Value("${spring.kafka.output.topic-name-contact}")
    private String contactOutputTopicName;

    @Value("${spring.kafka.output.topic-name-contact-answer}")
    private String contactAnswerOutputTopicName;

    @Value("${spring.kafka.output.topic-name-interview-note}")
    private String interviewNoteOutputTopicName;

    @Value("${spring.kafka.output.topic-name-rdb-metadata-columns}")
    private String rdbMetadataColumnsOutputTopicName;

    private final KafkaTemplate<String, String> kafkaTemplate;
    InvestigationKey investigationKey = new InvestigationKey();
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    private final InvestigationRepository investigationRepository;

    private static final String TYPE_CD = "type_cd";
    private static final String RDB_COLUMN_NM = "RDB_COLUMN_NM";

    @Transactional
    public InvestigationTransformed transformInvestigationData(Investigation investigation) {

        InvestigationTransformed investigationTransformed = new InvestigationTransformed(investigation.getPublicHealthCaseUid());

        transformPersonParticipations(investigation.getPersonParticipations(), investigationTransformed);
        transformCaseCountInfo(investigation.getInvestigationCaseCnt(), investigationTransformed);
        transformOrganizationParticipations(investigation.getOrganizationParticipations(), investigationTransformed);
        transformActIds(investigation.getActIds(), investigationTransformed);
        transformObservationIds(investigation.getInvestigationObservationIds(), investigationTransformed);
        transformInvestigationConfirmationMethod(investigation.getInvestigationConfirmationMethod(), investigationTransformed);
        processInvestigationPageCaseAnswer(investigation.getInvestigationCaseAnswer(), investigationTransformed);

        return investigationTransformed;
    }

    public void processInvestigationCaseManagement(String investigationCaseManagement) {
        try {
            JsonNode investigationCaseManagementArray = parseJsonArray(investigationCaseManagement);

            for (JsonNode jsonNode : investigationCaseManagementArray) {
                Long publicHealthCaseUid = jsonNode.get("public_health_case_uid").asLong();
                Long caseManagementUid = jsonNode.get("case_management_uid").asLong();

                InvestigationCaseManagementKey caseManagementKey = new InvestigationCaseManagementKey(publicHealthCaseUid, caseManagementUid);
                InvestigationCaseManagement caseManagement = objectMapper.treeToValue(jsonNode, InvestigationCaseManagement.class);

                String jsonKey = jsonGenerator.generateStringJson(caseManagementKey);
                String jsonValue = jsonGenerator.generateStringJson(caseManagement);
                kafkaTemplate.send(investigationCaseManagementTopicName, jsonKey, jsonValue)
                        .whenComplete((res, e) -> logger.info("Case Management data (uid={}) sent to {}", publicHealthCaseUid, investigationCaseManagementTopicName));
            }

        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "InvestigationCaseManagement");
        } catch (Exception e) {
            logger.error("Error processing Case Management JSON array from investigation data: {}", e.getMessage());
        }

    }

    public void processNotifications(String investigationNotifications) {
        try {
            JsonNode investigationNotificationsJsonArray = parseJsonArray(investigationNotifications);

            InvestigationNotificationKey investigationNotificationKey = new InvestigationNotificationKey();
            for (JsonNode node : investigationNotificationsJsonArray) {
                Long notificationUid = node.get("notification_uid").asLong();
                investigationNotificationKey.setNotificationUid(notificationUid);

                InvestigationNotification tempInvestigationNotificationObject = objectMapper.treeToValue(node, InvestigationNotification.class);

                String jsonKey = jsonGenerator.generateStringJson(investigationNotificationKey);
                String jsonValue = jsonGenerator.generateStringJson(tempInvestigationNotificationObject);
                kafkaTemplate.send(investigationNotificationsOutputTopicName, jsonKey, jsonValue)
                        .whenComplete((res, e) -> logger.info("Notification data (uid={}) sent to {}", notificationUid, investigationNotificationsOutputTopicName));
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "InvestigationNotification");
        } catch (Exception e) {
            logger.error("Error processing Notifications JSON array from investigation data: {}", e.getMessage());
        }
    }

    private void transformPersonParticipations(String personParticipations, InvestigationTransformed investigationTransformed) {
        try {
            JsonNode personParticipationsJsonArray = parseJsonArray(personParticipations);

            for (JsonNode node : personParticipationsJsonArray) {
                String typeCode = node.get(TYPE_CD).asText();
                String subjectClassCode = node.get("subject_class_cd").asText();
                String personCode = node.get("person_cd").asText();
                Long entityId = node.get("entity_id").asLong();

                if (typeCode.equals("InvestgrOfPHC") && subjectClassCode.equals("PSN") && personCode.equals("PRV")) {
                    investigationTransformed.setInvestigatorId(entityId);
                }
                if (typeCode.equals("PhysicianOfPHC") && subjectClassCode.equals("PSN") && personCode.equals("PRV")) {
                    investigationTransformed.setPhysicianId(entityId);
                }
                if (typeCode.equals("SubjOfPHC") && subjectClassCode.equals("PSN") && personCode.equals("PAT")) {
                    investigationTransformed.setPatientId(entityId);
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "PersonParticipations");
        } catch (Exception e) {
            logger.error("Error processing Person Participation JSON array from investigation data: {}", e.getMessage());
        }
    }

    private void transformCaseCountInfo(String caseCountInfo, InvestigationTransformed investigationTransformed) {
        try {
            JsonNode caseCountArray = parseJsonArray(caseCountInfo);
            //case count array will always have only one element
            for (JsonNode node : caseCountArray) {
                investigationTransformed.setInvestigationCount(node.get("investigation_count").asLong());
                investigationTransformed.setCaseCount(node.get("case_count").asLong());
                Optional.ofNullable(node.get("investigator_assigned_datetime")).filter(n -> !n.isNull())
                        .ifPresent(n -> investigationTransformed.setInvestigatorAssignedDatetime(n.asText()));
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "CaseCountInfo");
        } catch (Exception e) {
            logger.error("Error processing Case Count JSON array from investigation data: {}", e.getMessage());
        }
    }

    private void transformOrganizationParticipations(String organizationParticipations, InvestigationTransformed investigationTransformed) {
        try {
            JsonNode organizationParticipationsJsonArray = parseJsonArray(organizationParticipations);

            for (JsonNode node : organizationParticipationsJsonArray) {
                String typeCode = node.get(TYPE_CD).asText();
                String subjectClassCode = node.get("subject_class_cd").asText();

                if (typeCode.equals("OrgAsReporterOfPHC") && subjectClassCode.equals("ORG")) {
                    investigationTransformed.setOrganizationId(node.get("entity_id").asLong());
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "OrganizationParticipations");
        } catch (Exception e) {
            logger.error("Error processing Organization Participation JSON array from investigation data: {}", e.getMessage());
        }
    }

    private void transformActIds(String actIds, InvestigationTransformed investigationTransformed) {
        try {
            JsonNode actIdsJsonArray = parseJsonArray(actIds);

            for(JsonNode node : actIdsJsonArray) {
                int actIdSeq = node.get("act_id_seq").asInt();
                String typeCode = node.get(TYPE_CD).asText();
                String rootExtension = node.get("root_extension_txt").asText();

                if(typeCode.equals("STATE") && actIdSeq == 1) {
                    investigationTransformed.setInvStateCaseId(rootExtension);
                }
                if(typeCode.equals("CITY") && actIdSeq == 2) {
                    investigationTransformed.setCityCountyCaseNbr(rootExtension);
                }
                if(typeCode.equals("LEGACY") && actIdSeq == 3) {
                    investigationTransformed.setLegacyCaseId(rootExtension);
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "ActIds");
        } catch (Exception e) {
            logger.error("Error processing Act Ids JSON array from investigation data: {}", e.getMessage());
        }
    }

    private void transformObservationIds(String investigationObservationIds, InvestigationTransformed investigationTransformed) {
        try {
            JsonNode investigationObservationIdsJsonArray = parseJsonArray(investigationObservationIds);
            InvestigationObservation investigationObservation = new InvestigationObservation();
            InvestigationObservationKey investigationObservationKey = new InvestigationObservationKey();

            investigationKey.setPublicHealthCaseUid(investigationTransformed.getPublicHealthCaseUid());
            String jsonKey = jsonGenerator.generateStringJson(investigationKey);
            kafkaTemplate.send(investigationObservationOutputTopicName, jsonKey, null);

            for(JsonNode node : investigationObservationIdsJsonArray) {
                String sourceClassCode = node.path("source_class_cd").asText();
                String actTypeCode = node.path("act_type_cd").asText();
                Long sourceActId = node.get("source_act_uid").asLong();
                Long publicHealthCaseUid = node.get("public_health_case_uid").asLong();
                String rootTypeCd = node.path("act_type_cd").asText();

                if(sourceClassCode.equals("OBS") && actTypeCode.equals("PHCInvForm")) {
                    investigationTransformed.setPhcInvFormId(sourceActId);
                }

                investigationObservationKey.setPublicHealthCaseUid(publicHealthCaseUid);
                investigationObservationKey.setObservationId(sourceActId);
                investigationObservationKey.setBranchId(null);

                investigationObservation.setPublicHealthCaseUid(publicHealthCaseUid);
                investigationObservation.setObservationId(sourceActId);
                investigationObservation.setRootTypeCd(rootTypeCd);
                investigationObservation.setBranchId(null);
                investigationObservation.setBranchTypeCd(null);

                Optional.ofNullable(node.get("branch_uid")).filter(n -> !n.isNull())
                        .ifPresent(n -> {
                            investigationObservationKey.setBranchId(n.asLong());
                            investigationObservation.setBranchId(n.asLong());

                        });
                Optional.ofNullable(node.get("branch_type_cd")).filter(n -> !n.isNull())
                        .ifPresent(n -> investigationObservation.setBranchTypeCd(n.asText()));

                jsonKey = jsonGenerator.generateStringJson(investigationObservationKey);
                String jsonValue = jsonGenerator.generateStringJson(investigationObservation);
                kafkaTemplate.send(investigationObservationOutputTopicName, jsonKey, jsonValue);
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "InvestigationObservationIds");
        } catch (Exception e) {
            logger.error("Error processing Observation Ids JSON array from investigation data: {}", e.getMessage());
        }
    }

    private void transformInvestigationConfirmationMethod(String investigationConfirmationMethod, InvestigationTransformed investigationTransformed) {
        try {
            Long publicHealthCaseUid = investigationTransformed.getPublicHealthCaseUid();
            // Tombstone message to delete all confirmation methods for specified phc uid
            String jsonKey = jsonGenerator.generateStringJson(new InvestigationConfirmationMethodUidKey(publicHealthCaseUid));
            kafkaTemplate.send(investigationConfirmationOutputTopicName, jsonKey, null);

            JsonNode investigationConfirmationMethodJsonArray = parseJsonArray(investigationConfirmationMethod);

            InvestigationConfirmationMethodKey investigationConfirmationMethodKey = new InvestigationConfirmationMethodKey();
            InvestigationConfirmationMethod investigationConfirmation = new InvestigationConfirmationMethod();
            Map<String, String> confirmationMethodMap = new HashMap<>();
            String confirmationMethodTime = null;

            // Redundant time variable in case if confirmation_method_time is null in all rows of the array
            String phcLastChgTime = investigationConfirmationMethodJsonArray.get(0).get("phc_last_chg_time").asText();

            for(JsonNode node : investigationConfirmationMethodJsonArray) {
                JsonNode timeNode = node.get("confirmation_method_time");
                if (timeNode != null && !timeNode.isNull()) {
                    confirmationMethodTime = timeNode.asText();
                }
                confirmationMethodMap.put(node.get("confirmation_method_cd").asText(), node.get("confirmation_method_desc_txt").asText());
            }
            investigationConfirmation.setPublicHealthCaseUid(publicHealthCaseUid);
            investigationConfirmationMethodKey.setPublicHealthCaseUid(publicHealthCaseUid);

            investigationConfirmation.setConfirmationMethodTime(
                    confirmationMethodTime == null ? phcLastChgTime : confirmationMethodTime);

            for(Map.Entry<String, String> entry : confirmationMethodMap.entrySet()) {
                investigationConfirmation.setConfirmationMethodCd(entry.getKey());
                investigationConfirmation.setConfirmationMethodDescTxt(entry.getValue());
                investigationConfirmationMethodKey.setConfirmationMethodCd(entry.getKey());
                jsonKey = jsonGenerator.generateStringJson(investigationConfirmationMethodKey);
                String jsonValue = jsonGenerator.generateStringJson(investigationConfirmation);
                kafkaTemplate.send(investigationConfirmationOutputTopicName, jsonKey, jsonValue);
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "InvestigationConfirmationMethod");
        } catch (Exception e) {
            logger.error("Error processing investigation confirmation method JSON array from investigation data: {}", e.getMessage());
        }
    }

    private void processInvestigationPageCaseAnswer(String investigationCaseAnswer, InvestigationTransformed investigationTransformed) {
        try {
            Long publicHealthCaseUid = investigationTransformed.getPublicHealthCaseUid();

            // Tombstone message to delete all page case answers for specified actUid
            PageCaseAnswerUidKey pageCaseAnswerUidKey = new PageCaseAnswerUidKey(publicHealthCaseUid);
            String jsonKey = jsonGenerator.generateStringJson(pageCaseAnswerUidKey);
            kafkaTemplate.send(pageCaseAnswerOutputTopicName, jsonKey, null);

            JsonNode investigationCaseAnswerJsonArray = parseJsonArray(investigationCaseAnswer);

            Long actUid = investigationCaseAnswerJsonArray.get(0).get("act_uid").asLong();
            List<PageCaseAnswer> pageCaseAnswerList = new ArrayList<>();

            PageCaseAnswerKey pageCaseAnswerKey = new PageCaseAnswerKey();
            pageCaseAnswerKey.setActUid(actUid);

            for(JsonNode node : investigationCaseAnswerJsonArray) {
                PageCaseAnswer pageCaseAnswer = objectMapper.treeToValue(node, PageCaseAnswer.class);
                pageCaseAnswerList.add(pageCaseAnswer);

                pageCaseAnswerKey.setNbsCaseAnswerUid(pageCaseAnswer.getNbsCaseAnswerUid());
                jsonKey = jsonGenerator.generateStringJson(pageCaseAnswerKey);
                String jsonValue = jsonGenerator.generateStringJson(pageCaseAnswer);

                kafkaTemplate.send(pageCaseAnswerOutputTopicName, jsonKey, jsonValue);
            }

            String rdbTblNms = String.join(",", pageCaseAnswerList.stream()
                            .map(PageCaseAnswer::getRdbTableNm).collect(Collectors.toSet()));
            if (!rdbTblNms.isEmpty()) {
                investigationTransformed.setRdbTableNameList(rdbTblNms);
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "PageCaseAnswer");
        } catch (Exception e) {
            logger.error("Error processing investigation case answer JSON array from investigation data: {}", e.getMessage());
        }
    }

    @Transactional(isolation = Isolation.REPEATABLE_READ)
    public void processPhcFactDatamart(String publicHealthCaseUid) {
        try {
            // Calling sp_public_health_case_fact_datamart_event
            logger.info("Executing stored proc: sp_public_health_case_fact_datamart_event '{}' to populate PHС fact datamart", publicHealthCaseUid);
            investigationRepository.populatePhcFact(publicHealthCaseUid);
            logger.info("Stored proc execution completed: sp_public_health_case_fact_datamart_event '{}", publicHealthCaseUid);
        } catch (Exception dbe) {
            logger.warn("Error processing PHC fact datamart: {}", dbe.getMessage());
        }
    }

    private JsonNode parseJsonArray(String jsonString) throws JsonProcessingException, IllegalArgumentException {
        JsonNode jsonArray = jsonString != null ? objectMapper.readTree(jsonString) : null;
        if (jsonArray != null && jsonArray.isArray()) {
            return jsonArray;
        } else {
            throw new IllegalArgumentException("{} array is null.");
        }
    }

    /**
     * Utility method to transform and send kafka message for various nrt_interview_*** stage tables
     * @param interview Entity bean returned from stored procedures
     */
    public void processInterview(Interview interview) {
        try {

            // creating key for kafka
            InterviewReportingKey interviewReportingKey = new InterviewReportingKey();
            interviewReportingKey.setInterviewUid(interview.getInterviewUid());

            // constructing reporting(nrt) beans
            InterviewReporting interviewReporting = transformInterview(interview);

            /*
               sending reporting(nrt) beans as json to kafka
               starting with the nrt_interview and then
                   create and send nrt_interview_answer then
                   create and send nrt_interview_note
             */
            String jsonKey = jsonGenerator.generateStringJson(interviewReportingKey);
            String jsonValue = jsonGenerator.generateStringJson(interviewReporting, "interview_uid",
                    "investigation_uid", "provider_uid", "patient_uid", "notification_uid");
            kafkaTemplate.send(interviewOutputTopicName, jsonKey, jsonValue)
                    .whenComplete((res, e) -> logger.info("Interview data (uid={}) sent to {}", interview.getInterviewUid(), interviewOutputTopicName))
                    .thenRunAsync(() -> transformAndSendInterviewAnswer(interview))
                    .thenRunAsync(() -> transformAndSendInterviewNote(interview));

        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "Investigation Interview");
        } catch (Exception e) {
            logger.error("Error processing Investigation Interview or any of the associated data from interview data: {}", e.getMessage());
        }
    }

    private InterviewReporting transformInterview(Interview interview) {
        InterviewReporting investigationReporting = new InterviewReporting();
        investigationReporting.setInterviewUid(interview.getInterviewUid());
        investigationReporting.setInterviewDate(interview.getInterviewDate());
        investigationReporting.setInterviewLocCd(interview.getInterviewLocCd());
        investigationReporting.setInterviewTypeCd(interview.getInterviewTypeCd());
        investigationReporting.setInterviewStatusCd(interview.getInterviewStatusCd());
        investigationReporting.setIntervieweeRoleCd(interview.getIntervieweeRoleCd());
        investigationReporting.setIxIntervieweeRole(interview.getIxIntervieweeRole());
        investigationReporting.setAddTime(interview.getAddTime());
        investigationReporting.setAddUserId(interview.getAddUserId());
        investigationReporting.setIxLocation(interview.getIxLocation());
        investigationReporting.setIxStatus(interview.getIxStatus());
        investigationReporting.setIxType(interview.getIxType());
        investigationReporting.setLastChgTime(interview.getLastChgTime());
        investigationReporting.setLastChgUserId(interview.getLastChgUserId());
        investigationReporting.setRecordStatusTime(interview.getRecordStatusTime());
        investigationReporting.setRecordStatusCd(interview.getRecordStatusCd());
        investigationReporting.setLocalId(interview.getLocalId());
        investigationReporting.setVersionCtrlNbr(interview.getVersionCtrlNbr());
        investigationReporting.setInvestigationUid(interview.getInvestigationUid());
        investigationReporting.setOrganizationUid(interview.getOrganizationUid());
        investigationReporting.setProviderUid(interview.getProviderUid());
        investigationReporting.setPatientUid(interview.getPatientUid());
        return investigationReporting;
    }

    public void transformAndSendInterviewAnswer(Interview interview) {
        try {
            // Tombstone message to delete all interview answers for specified interview uid
            String jsonKey1 = jsonGenerator.generateStringJson(new InterviewReportingKey(interview.getInterviewUid()));
            kafkaTemplate.send(interviewAnswerOutputTopicName, jsonKey1, null);

            JsonNode answerArray = parseJsonArray(interview.getAnswers());

            for (JsonNode node : answerArray) {
                final Long interviewUid = interview.getInterviewUid();
                final String rdbColumnNm = node.get(RDB_COLUMN_NM).asText();

                InterviewAnswerKey interviewAnswerKey = new InterviewAnswerKey();
                interviewAnswerKey.setInterviewUid(interviewUid);
                interviewAnswerKey.setRdbColumnNm(rdbColumnNm);

                InterviewAnswer interviewAnswer = new InterviewAnswer();
                interviewAnswer.setInterviewUid(interviewUid);
                interviewAnswer.setRdbColumnNm(rdbColumnNm);
                interviewAnswer.setAnswerVal(node.get("ANSWER_VAL").asText());

                String jsonKey = jsonGenerator.generateStringJson(interviewAnswerKey);
                String jsonValue = jsonGenerator.generateStringJson(interviewAnswer);
                kafkaTemplate.send(interviewAnswerOutputTopicName, jsonKey, jsonValue)
                        .whenComplete((res, e) -> logger.info("Interview Answer data (uid={}) sent to {}", interview.getInterviewUid(), interviewAnswerOutputTopicName));

            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "Investigation Interview Answer");
        } catch (Exception e) {
            logger.error("Error processing Investigation Interview Answer JSON array from interview data: {}", e.getMessage());
        }
    }

    public void transformAndSendInterviewNote(Interview interview) {
        try {
            // Tombstone message to delete all interview note for specified interview uid
            String jsonKey1 = jsonGenerator.generateStringJson(new InterviewReportingKey(interview.getInterviewUid()));
            kafkaTemplate.send(interviewNoteOutputTopicName, jsonKey1, null);

            JsonNode answerArray = parseJsonArray(interview.getNotes());

            for (JsonNode node : answerArray) {
                final Long interviewUid = interview.getInterviewUid();
                final Long nbsAnswerUid = node.get("NBS_ANSWER_UID").asLong();

                InterviewNoteKey interviewNoteKey = new InterviewNoteKey();
                interviewNoteKey.setInterviewUid(interviewUid);
                interviewNoteKey.setNbsAnswerUid(nbsAnswerUid);

                InterviewNote interviewNote = new InterviewNote();
                interviewNote.setInterviewUid(interview.getInterviewUid());
                interviewNote.setNbsAnswerUid(nbsAnswerUid);
                interviewNote.setUserFirstName(node.get("USER_FIRST_NAME").asText());
                interviewNote.setUserLastName(node.get("USER_LAST_NAME").asText());
                interviewNote.setUserComment(node.get("USER_COMMENT").asText());
                interviewNote.setCommentDate(node.get("COMMENT_DATE").asText());
                interviewNote.setRecordStatusCd(node.get("RECORD_STATUS_CD").asText());

                String jsonKey = jsonGenerator.generateStringJson(interviewNoteKey);
                String jsonValue = jsonGenerator.generateStringJson(interviewNote);
                kafkaTemplate.send(interviewNoteOutputTopicName, jsonKey, jsonValue)
                        .whenComplete((res, e) -> logger.info("Interview Note data (uid={}) sent to {}", interview.getInterviewUid(), interviewNoteOutputTopicName));

            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "Investigation Interview Note");
        } catch (Exception e) {
            logger.error("Error processing Investigation Interview Note JSON array from interview data: {}", e.getMessage());
        }
    }

    /**
     * Utility method to transform and send kafka message for nrt_contact and nrt_contact_answer stage tables
     * @param contact Entity bean returned from stored procedures
     */
    public void processContact(Contact contact) {
        try {

            // creating key for kafka
            ContactReportingKey contactReportingKey = new ContactReportingKey();
            contactReportingKey.setContactUid(contact.getContactUid());

            // constructing reporting(nrt) beans
            ContactReporting contactReporting = transformContact(contact);

            /*
               sending reporting(nrt) beans as json to kafka
               starting with the nrt_contact and then
                   create and send nrt_contact_answer
             */
            String jsonKey = jsonGenerator.generateStringJson(contactReportingKey);
            String jsonValue = jsonGenerator.generateStringJson(contactReporting, "contact_uid");
            kafkaTemplate.send(contactOutputTopicName, jsonKey, jsonValue)
                    .whenComplete((res, e) -> logger.info("Contact Record data (uid={}) sent to {}", contact.getContactUid(), contactOutputTopicName))
                    .thenRunAsync(() -> transformAndSendContactAnswer(contact));

        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "Contact Record");
        } catch (Exception e) {
            logger.error("Error processing Contact Record or any of the associated data from contact data: {}", e.getMessage());
        }
    }

    private void transformAndSendContactAnswer(Contact contact) {
        try {

            JsonNode answerArray = parseJsonArray(contact.getAnswers());

            for (JsonNode node : answerArray) {
                final Long contactUid = contact.getContactUid();
                final String rdbColumnNm = node.get(RDB_COLUMN_NM).asText();

                ContactAnswerKey contactAnswerKey = new ContactAnswerKey();
                contactAnswerKey.setContactUid(contactUid);
                contactAnswerKey.setRdbColumnNm(rdbColumnNm);

                ContactAnswer contactAnswer = new ContactAnswer();
                contactAnswer.setContactUid(contactUid);
                contactAnswer.setRdbColumnNm(rdbColumnNm);
                contactAnswer.setAnswerVal(node.get("ANSWER_VAL").asText());

                String jsonKey = jsonGenerator.generateStringJson(contactAnswerKey);
                String jsonValue = jsonGenerator.generateStringJson(contactAnswer);
                kafkaTemplate.send(contactAnswerOutputTopicName, jsonKey, jsonValue)
                        .whenComplete((res, e) -> logger.info("Contact Record Answers data (uid={}) sent to {}", contact.getContactUid(), contactAnswerOutputTopicName));

            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "Contact Record Answer");
        } catch (Exception e) {
            logger.error("Error processing Contact Record Answer JSON array from contact data: {}", e.getMessage());
        }
    }

    private ContactReporting transformContact(Contact contact) {
        ContactReporting contactReporting = new ContactReporting();
        contactReporting.setContactUid(contact.getContactUid());
        contactReporting.setAddTime(contact.getAddTime());
        contactReporting.setAddUserId(contact.getAddUserId());
        contactReporting.setContactEntityEpiLinkId(contact.getContactEntityEpiLinkId());
        contactReporting.setContactEntityPhcUid(contact.getContactEntityPhcUid());
        contactReporting.setContactEntityUid(contact.getContactEntityUid());
        contactReporting.setCttReferralBasis(contact.getCttReferralBasis());
        contactReporting.setCttStatus(contact.getCttStatus());
        contactReporting.setCttDispoDt(contact.getCttDispoDt());
        contactReporting.setCttDisposition(contact.getCttDisposition());
        contactReporting.setCttEvalCompleted(contact.getCttEvalCompleted());
        contactReporting.setCttEvalDt(contact.getCttEvalDt());
        contactReporting.setCttEvalNotes(contact.getCttEvalNotes());
        contactReporting.setCttGroupLotId(contact.getCttGroupLotId());
        contactReporting.setCttHealthStatus(contact.getCttHealthStatus());
        contactReporting.setCttInvAssignedDt(contact.getCttInvAssignedDt());
        contactReporting.setCttJurisdictionNm(contact.getCttJurisdictionNm());
        contactReporting.setCttNamedOnDt(contact.getCttNamedOnDt());
        contactReporting.setCttNotes(contact.getCttNotes());
        contactReporting.setCttPriority(contact.getCttPriority());
        contactReporting.setCttProcessingDecision(contact.getCttProcessingDecision());
        contactReporting.setCttProgramArea(contact.getCttProgramArea());
        contactReporting.setCttRelationship(contact.getCttRelationship());
        contactReporting.setCttRiskInd(contact.getCttRiskInd());
        contactReporting.setCttRiskNotes(contact.getCttRiskNotes());
        contactReporting.setCttSharedInd(contact.getCttSharedInd());
        contactReporting.setCttSympInd(contact.getCttSympInd());
        contactReporting.setCttSympNotes(contact.getCttSympNotes());
        contactReporting.setCttSympOnsetDt(contact.getCttSympOnsetDt());
        contactReporting.setThirdPartyEntityPhcUid(contact.getThirdPartyEntityPhcUid());
        contactReporting.setThirdPartyEntityUid(contact.getThirdPartyEntityUid());
        contactReporting.setCttTrtCompleteInd(contact.getCttTrtCompleteInd());
        contactReporting.setCttTrtEndDt(contact.getCttTrtEndDt());
        contactReporting.setCttTrtInitiatedInd(contact.getCttTrtInitiatedInd());
        contactReporting.setCttTrtNotCompleteRsn(contact.getCttTrtNotCompleteRsn());
        contactReporting.setCttTrtNotStartRsn(contact.getCttTrtNotStartRsn());
        contactReporting.setCttTrtNotes(contact.getCttTrtNotes());
        contactReporting.setCttTrtStartDt(contact.getCttTrtStartDt());
        contactReporting.setLastChgTime(contact.getLastChgTime());
        contactReporting.setLastChgUserId(contact.getLastChgUserId());
        contactReporting.setLocalId(contact.getLocalId());
        contactReporting.setNamedDuringInterviewUid(contact.getNamedDuringInterviewUid());
        contactReporting.setProgramJurisdictionOid(contact.getProgramJurisdictionOid());
        contactReporting.setRecordStatusCd(contact.getRecordStatusCd());
        contactReporting.setRecordStatusTime(contact.getRecordStatusTime());
        contactReporting.setSubjectEntityEpiLinkId(contact.getSubjectEntityEpiLinkId());
        contactReporting.setSubjectEntityPhcUid(contact.getSubjectEntityPhcUid());
        contactReporting.setVersionCtrlNbr(contact.getVersionCtrlNbr());
        contactReporting.setContactExposureSiteUid(contact.getContactExposureSiteUid());
        contactReporting.setProviderContactInvestigatorUid(contact.getProviderContactInvestigatorUid());
        contactReporting.setDispositionedByUid(contact.getDispositionedByUid());
        return contactReporting;
    }

    /**
     * Parse and send RDB metadata column information sourced from the odse nbs_rdb_metadata
     * To a generic kafka topic to handle all types of rdb column metadata
     * This is now being used from interview service but can be reused from other service functions
     * @param rdbCols - rdb metadata column information
     * @param uid - the uid of the domain (e.g. interviewUid) invoking this method
     */
    public void processColumnMetadata(String rdbCols, Long uid) {
        try {
            JsonNode columnArray = parseJsonArray(rdbCols);
            for (JsonNode node : columnArray) {
                String tableName = node.get("TABLE_NAME").asText();
                String columnName = node.get(RDB_COLUMN_NM).asText();

                // creating key for kafka
                MetadataColumnKey metadataColumnKey = new MetadataColumnKey();
                metadataColumnKey.setTableName(tableName);
                metadataColumnKey.setRdbColumnName(columnName);

                MetadataColumn metadataColumn = new MetadataColumn();
                metadataColumn.setTableName(tableName);
                metadataColumn.setRdbColumnNm(columnName);
                metadataColumn.setNewFlag(node.get("NEW_FLAG").asInt());
                metadataColumn.setLastChgTime(node.get("LAST_CHG_TIME").asText());
                metadataColumn.setLastChgUserId(node.get("LAST_CHG_USER_ID").asLong());

                String jsonKey = jsonGenerator.generateStringJson(metadataColumnKey);
                String jsonValue = jsonGenerator.generateStringJson(metadataColumn);

                kafkaTemplate.send(rdbMetadataColumnsOutputTopicName, jsonKey, jsonValue)
                        .whenComplete((res, e) -> logger.info("RDB column metadata (uid={}) sent to {}", uid, rdbMetadataColumnsOutputTopicName));
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "RDB Column Metadata");
        } catch (Exception e) {
            logger.error("Error processing RDB Column Metadata JSON array from data: {}", e.getMessage());
        }

    }
}
