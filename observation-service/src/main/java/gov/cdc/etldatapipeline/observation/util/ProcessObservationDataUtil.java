package gov.cdc.etldatapipeline.observation.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.etldatapipeline.commonutil.json.CustomJsonGeneratorImpl;
import gov.cdc.etldatapipeline.observation.repository.model.dto.Observation;
import gov.cdc.etldatapipeline.observation.repository.model.dto.ObservationTransformed;
import gov.cdc.etldatapipeline.observation.repository.model.reporting.*;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.function.Function;

@Component
@RequiredArgsConstructor @Setter
public class ProcessObservationDataUtil {
    private static final Logger logger = LoggerFactory.getLogger(ProcessObservationDataUtil.class);
    private static final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final CustomJsonGeneratorImpl jsonGenerator = new CustomJsonGeneratorImpl();

    @Value("${spring.kafka.output.topic-name-coded}")
    public String codedTopicName;

    @Value("${spring.kafka.output.topic-name-date}")
    public String dateTopicName;

    @Value("${spring.kafka.output.topic-name-edx}")
    public String edxTopicName;

    @Value("${spring.kafka.output.topic-name-material}")
    public String materialTopicName;

    @Value("${spring.kafka.output.topic-name-numeric}")
    public String numericTopicName;

    @Value("${spring.kafka.output.topic-name-reason}")
    public String reasonTopicName;

    @Value("${spring.kafka.output.topic-name-txt}")
    public String txtTopicName;

    ObservationKey observationKey = new ObservationKey();

    private static final String SUBJECT_CLASS_CD = "subject_class_cd";
    public static final String TYPE_CD = "type_cd";
    public static final String ENTITY_ID = "entity_id";
    public static final String ORDER = "Order";
    public static final String RESULT = "Result";

    public ObservationTransformed transformObservationData(Observation observation) {
        ObservationTransformed observationTransformed = new ObservationTransformed();
        observationTransformed.setObservationUid(observation.getObservationUid());
        observationTransformed.setReportObservationUid(observation.getObservationUid());

        String obsDomainCdSt1 = observation.getObsDomainCdSt1();

        transformPersonParticipations(observation.getPersonParticipations(), obsDomainCdSt1, observationTransformed);
        transformOrganizationParticipations(observation.getOrganizationParticipations(), obsDomainCdSt1, observationTransformed);
        transformMaterialParticipations(observation.getMaterialParticipations(), obsDomainCdSt1, observationTransformed);
        transformFollowupObservations(observation.getFollowupObservations(), obsDomainCdSt1, observationTransformed);
        transformParentObservations(observation.getParentObservations(), observationTransformed);
        transformActIds(observation.getActIds(), observationTransformed);
        transformObservationCoded(observation.getObsCode());
        transformObservationDate(observation.getObsDate());
        transformObservationEdx(observation.getEdxIds());
        transformObservationNumeric(observation.getObsNum());
        transformObservationReasons(observation.getObsReason());
        transformObservationTxt(observation.getObsTxt());

        return observationTransformed;
    }

    private void transformPersonParticipations(String personParticipations, String obsDomainCdSt1, ObservationTransformed observationTransformed) {
        try {
            JsonNode personParticipationsJsonArray = parseJsonArray(personParticipations);

            for (JsonNode jsonNode : personParticipationsJsonArray) {
                assertDomainCdMatches(obsDomainCdSt1, ORDER, RESULT);

                String typeCd = getNodeValue(jsonNode, TYPE_CD, JsonNode::asText);
                Long entityId = getNodeValue(jsonNode, ENTITY_ID, JsonNode::asLong);

                if (typeCd.equals("PATSBJ")) {
                    transformPersonParticipationRoles(jsonNode, observationTransformed, entityId);
                }

                if (ORDER.equals(obsDomainCdSt1)) {
                    String subjectClassCd = getNodeValue(jsonNode, SUBJECT_CLASS_CD, JsonNode::asText);
                    if ("PSN".equals(subjectClassCd)) {
                        switch (typeCd) {
                            case "ORD":
                                observationTransformed.setOrderingPersonId(entityId);
                                break;
                            case "PATSBJ", "SubjOfMorbReport":
                                observationTransformed.setPatientId(entityId);
                                break;
                            case "PhysicianOfMorb":
                                observationTransformed.setMorbPhysicianId(entityId);
                                break;
                            case "ReporterOfMorbReport":
                                observationTransformed.setMorbReporterId(entityId);
                                break;
                            case "ENT":
                                observationTransformed.setTranscriptionistId(entityId);
                                Optional.ofNullable(jsonNode.get("first_nm")).filter(n -> !n.isNull())
                                        .ifPresent(n -> observationTransformed.setTranscriptionistFirstNm(n.asText()));
                                Optional.ofNullable(jsonNode.get("last_nm")).filter(n -> !n.isNull())
                                        .ifPresent(n -> observationTransformed.setTranscriptionistLastNm(n.asText()));
                                Optional.ofNullable(jsonNode.get("person_id_val")).filter(n -> !n.isNull())
                                        .ifPresent(n -> observationTransformed.setTranscriptionistVal(n.asText()));
                                Optional.ofNullable(jsonNode.get("person_id_assign_auth_cd")).filter(n -> !n.isNull())
                                        .ifPresent(n -> observationTransformed.setTranscriptionistIdAssignAuth(n.asText()));
                                Optional.ofNullable(jsonNode.get("person_id_type_desc")).filter(n -> !n.isNull())
                                        .ifPresent(n -> observationTransformed.setTranscriptionistAuthType(n.asText()));
                                break;
                            case "ASS":
                                observationTransformed.setAssistantInterpreterId(entityId);
                                Optional.ofNullable(jsonNode.get("first_nm")).filter(n -> !n.isNull())
                                        .ifPresent(n -> observationTransformed.setAssistantInterpreterFirstNm(n.asText()));
                                Optional.ofNullable(jsonNode.get("last_nm")).filter(n -> !n.isNull())
                                        .ifPresent(n -> observationTransformed.setAssistantInterpreterLastNm(n.asText()));
                                Optional.ofNullable(jsonNode.get("person_id_val")).filter(n -> !n.isNull())
                                        .ifPresent(n -> observationTransformed.setAssistantInterpreterVal(n.asText()));
                                Optional.ofNullable(jsonNode.get("person_id_assign_auth_cd")).filter(n -> !n.isNull())
                                        .ifPresent(n -> observationTransformed.setAssistantInterpreterIdAssignAuth(n.asText()));
                                Optional.ofNullable(jsonNode.get("person_id_type_desc")).filter(n -> !n.isNull())
                                        .ifPresent(n -> observationTransformed.setAssistantInterpreterAuthType(n.asText()));
                                break;
                            case "VRF":
                                observationTransformed.setResultInterpreterId(entityId);
                                break;
                            case "PRF":
                                observationTransformed.setLabTestTechnicianId(entityId);
                                break;
                            default:
                        }
                    }
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "PersonParticipations", personParticipations);
        } catch (Exception e) {
            logger.error("Error processing Person Participation JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformPersonParticipationRoles(JsonNode node, ObservationTransformed observationTransformed, Long entityId) {
        String roleSubject = node.path("role_subject_class_cd").asText();
        if ("PROV".equals(roleSubject)) {
            String roleCd = node.path("role_cd").asText();
            if ("SPP".equals(roleCd)) {
                String roleScoping = node.path("role_scoping_class_cd").asText();
                if ("PSN".equals(roleScoping)) {
                    observationTransformed.setSpecimenCollectorId(entityId);
                }
            } else if ("CT".equals(roleCd)) {
                observationTransformed.setCopyToProviderId(entityId);
            }
        }
    }

    private void transformOrganizationParticipations(String organizationParticipations, String obsDomainCdSt1, ObservationTransformed observationTransformed) {
        try {
            JsonNode organizationParticipationsJsonArray = parseJsonArray(organizationParticipations);

            for (JsonNode jsonNode : organizationParticipationsJsonArray) {
                assertDomainCdMatches(obsDomainCdSt1, RESULT, ORDER);

                String typeCd = getNodeValue(jsonNode, TYPE_CD, JsonNode::asText);
                String subjectClassCd = getNodeValue(jsonNode, SUBJECT_CLASS_CD, JsonNode::asText);
                Long entityId = getNodeValue(jsonNode, ENTITY_ID, JsonNode::asLong);

                if (subjectClassCd.equals("ORG")) {
                    if (RESULT.equals(obsDomainCdSt1)) {
                        if ("PRF".equals(typeCd)) {
                            observationTransformed.setPerformingOrganizationId(entityId);
                        }
                    } else if (ORDER.equals(obsDomainCdSt1)) {
                        switch (typeCd) {
                            case "AUT":
                                observationTransformed.setAuthorOrganizationId(entityId);
                                break;
                            case "ORD":
                                observationTransformed.setOrderingOrganizationId(entityId);
                                break;
                            case "HCFAC":
                                observationTransformed.setHealthCareId(entityId);
                                break;
                            case "ReporterOfMorbReport":
                                observationTransformed.setMorbHospReporterId(entityId);
                                break;
                            case "HospOfMorbObs":
                                observationTransformed.setMorbHospId(entityId);
                                break;
                            default:
                                break;
                        }
                    }
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "OrganizationParticipations", organizationParticipations);
        } catch (Exception e) {
            logger.error("Error processing Organization Participation JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformMaterialParticipations(String materialParticipations, String obsDomainCdSt1, ObservationTransformed observationTransformed) {
        try {
            JsonNode materialParticipationsJsonArray = parseJsonArray(materialParticipations);

            for (JsonNode jsonNode : materialParticipationsJsonArray) {
                String typeCd = getNodeValue(jsonNode, TYPE_CD, JsonNode::asText);
                String subjectClassCd = getNodeValue(jsonNode, SUBJECT_CLASS_CD, JsonNode::asText);

                assertDomainCdMatches(obsDomainCdSt1, ORDER);
                if ("SPC".equals(typeCd) && "MAT".equals(subjectClassCd)) {
                    Long materialId = jsonNode.get(ENTITY_ID).asLong();
                    observationTransformed.setMaterialId(materialId);

                    ObservationMaterial material = objectMapper.treeToValue(jsonNode, ObservationMaterial.class);
                    material.setMaterialId(materialId);
                    ObservationMaterialKey key = new ObservationMaterialKey();
                    key.setMaterialId(observationTransformed.getMaterialId());
                    sendToKafka(key, material, materialTopicName, materialId, "Observation Material data (uid={}) sent to {}");
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "MaterialParticipations", materialParticipations);
        } catch (Exception e) {
            logger.error("Error processing Material Participation JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformFollowupObservations(String followupObservations, String obsDomainCdSt1, ObservationTransformed observationTransformed) {
        try {
            JsonNode followupObservationsJsonArray = parseJsonArray(followupObservations);

            List<String> results = new ArrayList<>();
            List<String> followUps = new ArrayList<>();
            for (JsonNode jsonNode : followupObservationsJsonArray) {
                Optional<JsonNode> domainCd = Optional.ofNullable(jsonNode.get("domain_cd_st_1"));
                assertDomainCdMatches(obsDomainCdSt1, ORDER);

                if (domainCd.isPresent() && RESULT.equals(domainCd.get().asText())) {
                    Optional.ofNullable(jsonNode.get("result_observation_uid")).ifPresent(r -> results.add(r.asText()));
                } else {
                    Optional.ofNullable(jsonNode.get("result_observation_uid")).ifPresent(r -> followUps.add(r.asText()));
                }
            }

            if(!results.isEmpty()) {
                observationTransformed.setResultObservationUid(String.join(",", results));
            }
            if(!followUps.isEmpty()) {
                observationTransformed.setFollowUpObservationUid(String.join(",", followUps));
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "FollowupObservations", followupObservations);
        } catch (Exception e) {
            logger.error("Error processing Followup Observations JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformParentObservations(String parentObservations, ObservationTransformed observationTransformed) {
        try {
            JsonNode parentObservationsJsonArray = parseJsonArray(parentObservations);

            for (JsonNode jsonNode : parentObservationsJsonArray) {
                Long parentUid = getNodeValue(jsonNode, "parent_uid", JsonNode::asLong);
                String parentTypeCd = jsonNode.path("parent_type_cd").asText();
                String parentDomainCd = jsonNode.path("parent_domain_cd_st_1").asText();

                if (parentTypeCd.equals("SPRT")) {
                    observationTransformed.setReportSprtUid(parentUid);
                } else if (parentTypeCd.equals("REFR")) {
                    observationTransformed.setReportRefrUid(parentUid);
                }

                if (parentDomainCd.contains(ORDER)) {
                    observationTransformed.setReportObservationUid(parentUid);
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "ParentObservations", parentObservations);
        } catch (Exception e) {
            logger.error("Error processing Parent Observations JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformActIds(String actIds, ObservationTransformed observationTransformed) {
        try {
            JsonNode actIdsJsonArray = parseJsonArray(actIds);

            for (JsonNode jsonNode : actIdsJsonArray) {
                String typeCd = getNodeValue(jsonNode, TYPE_CD, JsonNode::asText);
                if (typeCd.equals("FN")) {
                    String rootExtTxt = getNodeValue(jsonNode, "root_extension_txt", JsonNode::asText);
                    observationTransformed.setAccessionNumber(rootExtTxt);
                }
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "ActIds", actIds);
        } catch (Exception e) {
            logger.error("Error processing Act Ids JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformObservationCoded(String observationCoded) {
        try {
            JsonNode observationCodedJsonArray = parseJsonArray(observationCoded);

            ObservationCodedKey codedKey = new ObservationCodedKey();
            for (JsonNode jsonNode : observationCodedJsonArray) {
                ObservationCoded coded = objectMapper.treeToValue(jsonNode, ObservationCoded.class);
                codedKey.setObservationUid(coded.getObservationUid());
                codedKey.setOvcCode(coded.getOvcCode());
                sendToKafka(codedKey, coded, codedTopicName, coded.getObservationUid(), "Observation Coded data (uid={}) sent to {}");
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "ObservationCoded");
        } catch (Exception e) {
            logger.error("Error processing Observation Coded JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformObservationDate(String observationDate) {
        try {
            JsonNode observationDateJsonArray = parseJsonArray(observationDate);

            for (JsonNode jsonNode : observationDateJsonArray) {
                ObservationDate coded = objectMapper.treeToValue(jsonNode, ObservationDate.class);
                observationKey.setObservationUid(coded.getObservationUid());
                sendToKafka(observationKey, coded, dateTopicName, coded.getObservationUid(), "Observation Date data (uid={}) sent to {}");
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "ObservationDate");
        } catch (Exception e) {
            logger.error("Error processing Observation Date JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformObservationEdx(String observationEdx) {
        try {
            JsonNode observationEdxJsonArray = parseJsonArray(observationEdx);
            ObservationEdxKey edxKey = new ObservationEdxKey();

            for (JsonNode jsonNode : observationEdxJsonArray) {
                ObservationEdx edx = objectMapper.treeToValue(jsonNode, ObservationEdx.class);
                edxKey.setEdxDocumentUid(edx.getEdxDocumentUid());
                sendToKafka(edxKey, edx, edxTopicName, edx.getEdxDocumentUid(), "Observation Edx data (edx doc uid={}) sent to {}");
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "ObservationEdx");
        } catch (Exception e) {
            logger.error("Error processing Observation Edx JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformObservationNumeric(String observationNumeric) {
        try {
            JsonNode observationNumericJsonArray = parseJsonArray(observationNumeric);

            for (JsonNode jsonNode : observationNumericJsonArray) {
                ObservationNumeric numeric = objectMapper.treeToValue(jsonNode, ObservationNumeric.class);
                observationKey.setObservationUid(numeric.getObservationUid());
                sendToKafka(observationKey, numeric, numericTopicName, numeric.getObservationUid(), "Observation Numeric data (uid={}) sent to {}");
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "ObservationNumeric");
        } catch (Exception e) {
            logger.error("Error processing Observation Numeric JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformObservationReasons(String observationReasons) {
        try {
            JsonNode observationReasonsJsonArray = parseJsonArray(observationReasons);

            ObservationReasonKey reasonKey = new ObservationReasonKey();
            for (JsonNode jsonNode : observationReasonsJsonArray) {
                ObservationReason reason = objectMapper.treeToValue(jsonNode, ObservationReason.class);
                reasonKey.setObservationUid(reason.getObservationUid());
                reasonKey.setReasonCd(reason.getReasonCd());
                sendToKafka(reasonKey, reason, reasonTopicName, reason.getObservationUid(), "Observation Reason data (uid={}) sent to {}");
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "ObservationReasons");
        } catch (Exception e) {
            logger.error("Error processing Observation Reasons JSON array from observation data: {}", e.getMessage());
        }
    }

    private void transformObservationTxt(String observationTxt) {
        try {
            JsonNode observationTxtJsonArray = parseJsonArray(observationTxt);

            ObservationTxtKey txtKey = new ObservationTxtKey();
            for (JsonNode jsonNode : observationTxtJsonArray) {
                ObservationTxt txt = objectMapper.treeToValue(jsonNode, ObservationTxt.class);
                txtKey.setObservationUid(txt.getObservationUid());
                txtKey.setOvtSeq(txt.getOvtSeq());
                sendToKafka(txtKey, txt, txtTopicName, txt.getObservationUid(), "Observation Txt data (uid={}) sent to {}");
            }
        } catch (IllegalArgumentException ex) {
            logger.info(ex.getMessage(), "ObservationTxt");
        } catch (Exception e) {
            logger.error("Error processing Observation Txt JSON array from observation data: {}", e.getMessage());
        }
    }

    private void sendToKafka(Object key, Object value, String topicName, Long uid, String message) {
        String jsonKey = jsonGenerator.generateStringJson(key);
        String jsonValue = jsonGenerator.generateStringJson(value);
        kafkaTemplate.send(topicName, jsonKey, jsonValue)
                .whenComplete((res, e) -> logger.info(message, uid, topicName));
    }

    private JsonNode parseJsonArray(String jsonString) throws JsonProcessingException, IllegalArgumentException {
        JsonNode jsonArray = jsonString != null ? objectMapper.readTree(jsonString) : null;
        if (jsonArray != null && jsonArray.isArray()) {
            return jsonArray;
        } else {
            throw new IllegalArgumentException("{} array is null.");
        }
    }

    private <T> T getNodeValue(JsonNode jsonNode, String fieldName, Function<JsonNode, T> mapper) {
        JsonNode node = jsonNode.get(fieldName);
        if (node == null || node.isNull()) {
            throw new IllegalArgumentException("Field " + fieldName + " is null or not found in {}: {}");
        }
        return mapper.apply(node);
    }

    private void assertDomainCdMatches(String value, String... vals ) {
        if (Arrays.stream(vals).noneMatch(value::equals)) {
            throw new IllegalArgumentException("obsDomainCdSt1: " + value + " is not valid for the {}");
        }
    }
}
