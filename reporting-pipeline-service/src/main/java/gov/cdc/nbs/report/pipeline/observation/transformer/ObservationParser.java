package gov.cdc.nbs.report.pipeline.observation.transformer;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.Observation;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationCoded;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationDate;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationEdx;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationMaterial;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationNumeric;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationReason;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationTransformed;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ObservationTxt;
import gov.cdc.nbs.report.pipeline.observation.model.dto.observation.ParsedObservation;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.function.Consumer;
import java.util.function.Function;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ObservationParser {
  private static final Logger logger = LoggerFactory.getLogger(ObservationParser.class);
  private static final ObjectMapper objectMapper =
      new ObjectMapper().registerModule(new JavaTimeModule());

  private static final String SUBJECT_CLASS_CD = "subject_class_cd";
  public static final String TYPE_CD = "type_cd";
  public static final String ENTITY_ID = "entity_id";
  public static final String ORDER = "Order";
  public static final String RESULT = "Result";
  public static final String ACT_ID_SEQ = "act_id_seq";
  public static final String ROOT_EXTENSION_TXT = "root_extension_txt";

  private ObservationParser() {}

  public static ParsedObservation parse(final Observation observation, final long batchId) {
    ParsedObservation parsedObservation = new ParsedObservation(new ObservationTransformed());
    ObservationTransformed observationTransformed = parsedObservation.transformed();

    observationTransformed.setObservationUid(observation.getObservationUid());
    observationTransformed.setReportObservationUid(observation.getObservationUid());
    observationTransformed.setBatchId(batchId);

    // Person Participations
    setPersonParticipations(
        observation.getPersonParticipations(),
        observation.getObsDomainCdSt1(),
        observationTransformed);

    // Organization Participations
    setOrganizationParticipations(
        observation.getOrganizationParticipations(),
        observation.getObsDomainCdSt1(),
        observationTransformed);

    // Material Participations
    setMaterialParticipations(
        observation.getMaterialParticipations(),
        observation.getObsDomainCdSt1(),
        parsedObservation);

    // Follow up Observations
    setFollowupObservations(
        observation.getFollowupObservations(),
        observation.getObsDomainCdSt1(),
        observationTransformed);

    // Parent Observations
    setParentObservations(observation.getParentObservations(), observationTransformed);

    // Act Ids
    setActIds(observation.getActIds(), observationTransformed);

    // Observation Coded data
    setObservationCoded(observation.getObsCode(), parsedObservation);

    // Observation Date data
    setObservationDate(observation.getObsDate(), parsedObservation);

    // Observation Edx data
    setObservationEdx(observation.getEdxIds(), parsedObservation);

    // Observation Numeric data
    setObservationNumeric(observation.getObsNum(), parsedObservation);

    // Observation Reason data
    setObservationReasons(observation.getObsReason(), parsedObservation);

    // Observation Text data
    setObservationTxt(observation.getObsTxt(), parsedObservation);

    return parsedObservation;
  }

  private static void setPersonParticipations(
      String personParticipations, String obsDomainCdSt1, ObservationTransformed transformed) {
    try {
      JsonNode personParticipationsJsonArray = parseJsonArray(personParticipations);

      List<String> orderers = new ArrayList<>();
      for (JsonNode jsonNode : personParticipationsJsonArray) {
        assertDomainCdMatches(obsDomainCdSt1, ORDER, RESULT);

        String typeCd = getNodeValue(jsonNode, TYPE_CD, JsonNode::asText);
        Long entityId = getNodeValue(jsonNode, ENTITY_ID, JsonNode::asLong);

        if (typeCd.equals("PATSBJ")) {
          setPersonParticipationRoles(jsonNode, transformed, entityId);
        }

        if (ORDER.equals(obsDomainCdSt1)) {
          String subjectClassCd = getNodeValue(jsonNode, SUBJECT_CLASS_CD, JsonNode::asText);
          if ("PSN".equals(subjectClassCd)) {
            switch (typeCd) {
              case "ORD":
                orderers.add(String.valueOf(entityId));
                break;
              case "PATSBJ", "SubjOfMorbReport":
                transformed.setPatientId(entityId);
                break;
              case "PhysicianOfMorb":
                transformed.setMorbPhysicianId(entityId);
                break;
              case "ReporterOfMorbReport":
                transformed.setMorbReporterId(entityId);
                break;
              case "ENT":
                transformed.setTranscriptionistId(entityId);

                ifPresentSet(jsonNode, "first_nm", transformed::setTranscriptionistFirstNm);
                ifPresentSet(jsonNode, "last_nm", transformed::setTranscriptionistLastNm);
                ifPresentSet(jsonNode, "person_id_val", transformed::setTranscriptionistVal);
                ifPresentSet(
                    jsonNode,
                    "person_id_assign_auth_cd",
                    transformed::setTranscriptionistIdAssignAuth);
                ifPresentSet(
                    jsonNode, "person_id_type_desc", transformed::setTranscriptionistAuthType);
                break;
              case "ASS":
                transformed.setAssistantInterpreterId(entityId);

                ifPresentSet(jsonNode, "first_nm", transformed::setAssistantInterpreterFirstNm);
                ifPresentSet(jsonNode, "last_nm", transformed::setAssistantInterpreterLastNm);
                ifPresentSet(jsonNode, "person_id_val", transformed::setAssistantInterpreterVal);
                ifPresentSet(
                    jsonNode,
                    "person_id_assign_auth_cd",
                    transformed::setAssistantInterpreterIdAssignAuth);
                ifPresentSet(
                    jsonNode, "person_id_type_desc", transformed::setAssistantInterpreterAuthType);
                break;
              case "VRF":
                transformed.setResultInterpreterId(entityId);
                break;
              case "PRF":
                transformed.setLabTestTechnicianId(entityId);
                break;
              default:
            }
          }
        }
      }
      if (!orderers.isEmpty()) {
        transformed.setOrderingPersonId(String.join(",", orderers));
      }
    } catch (IllegalArgumentException ex) {
      logger.info(ex.getMessage(), "PersonParticipations", personParticipations);
    } catch (Exception e) {
      logger.error(
          "Error processing Person Participation JSON array from observation data: {}",
          e.getMessage());
    }
  }

  private static void setOrganizationParticipations(
      String organizationParticipations,
      String obsDomainCdSt1,
      ObservationTransformed transformed) {
    try {
      JsonNode organizationParticipationsJsonArray = parseJsonArray(organizationParticipations);

      for (JsonNode jsonNode : organizationParticipationsJsonArray) {
        assertDomainCdMatches(obsDomainCdSt1, RESULT, ORDER);

        String typeCd = getNodeValue(jsonNode, TYPE_CD, JsonNode::asText);
        String subjectClassCd = getNodeValue(jsonNode, SUBJECT_CLASS_CD, JsonNode::asText);
        Long entityId = getNodeValue(jsonNode, ENTITY_ID, JsonNode::asLong);

        if (subjectClassCd.equals("ORG")) {

          if (RESULT.equals(obsDomainCdSt1) && "PRF".equals(typeCd)) {
            transformed.setPerformingOrganizationId(entityId);
          } else if (ORDER.equals(obsDomainCdSt1)) {
            switch (typeCd) {
              case "AUT":
                transformed.setAuthorOrganizationId(entityId);
                break;
              case "ORD":
                transformed.setOrderingOrganizationId(entityId);
                break;
              case "HCFAC":
                transformed.setHealthCareId(entityId);
                break;
              case "ReporterOfMorbReport":
                transformed.setMorbHospReporterId(entityId);
                break;
              case "HospOfMorbObs":
                transformed.setMorbHospId(entityId);
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
      logger.error(
          "Error processing Organization Participation JSON array from observation data: {}",
          e.getMessage());
    }
  }

  private static void setMaterialParticipations(
      String materialParticipations, String obsDomainCdSt1, ParsedObservation parsedObservation) {
    try {
      JsonNode materialParticipationsJsonArray = parseJsonArray(materialParticipations);

      for (JsonNode jsonNode : materialParticipationsJsonArray) {
        String typeCd = getNodeValue(jsonNode, TYPE_CD, JsonNode::asText);
        String subjectClassCd = getNodeValue(jsonNode, SUBJECT_CLASS_CD, JsonNode::asText);

        assertDomainCdMatches(obsDomainCdSt1, ORDER);
        if ("SPC".equals(typeCd) && "MAT".equals(subjectClassCd)) {
          Long materialId = jsonNode.get(ENTITY_ID).asLong();
          parsedObservation.transformed().setMaterialId(materialId);

          ObservationMaterial material =
              objectMapper.treeToValue(jsonNode, ObservationMaterial.class);
          material.setMaterialId(materialId);

          // Add material to list that will be persisted to the database
          parsedObservation.materialEntries().add(material);
        }
      }
    } catch (IllegalArgumentException ex) {
      logger.info(ex.getMessage(), "MaterialParticipations", materialParticipations);
    } catch (Exception e) {
      logger.error(
          "Error processing Material Participation JSON array from observation data: {}",
          e.getMessage());
    }
  }

  private static void setPersonParticipationRoles(
      JsonNode node, ObservationTransformed observationTransformed, Long entityId) {
    String roleSubject = fieldAsText(node, "role_subject_class_cd");
    if ("PROV".equals(roleSubject)) {
      String roleCd = fieldAsText(node, "role_cd");
      if ("SPP".equals(roleCd)) {
        String roleScoping = fieldAsText(node, "role_scoping_class_cd");
        if ("PSN".equals(roleScoping)) {
          observationTransformed.setSpecimenCollectorId(entityId);
        }
      } else if ("CT".equals(roleCd)) {
        observationTransformed.setCopyToProviderId(entityId);
      }
    }
  }

  private static void setFollowupObservations(
      String followupObservations, String obsDomainCdSt1, ObservationTransformed transformed) {
    try {
      JsonNode followupObservationsJsonArray = parseJsonArray(followupObservations);

      List<String> results = new ArrayList<>();
      List<String> followUps = new ArrayList<>();
      for (JsonNode jsonNode : followupObservationsJsonArray) {
        String domainCd = fieldAsText(jsonNode, "domain_cd_st_1");
        assertDomainCdMatches(obsDomainCdSt1, ORDER);

        if (RESULT.equals(domainCd)) {
          Optional.ofNullable(jsonNode.get("result_observation_uid"))
              .ifPresent(r -> results.add(r.asText()));
        } else {
          Optional.ofNullable(jsonNode.get("result_observation_uid"))
              .ifPresent(r -> followUps.add(r.asText()));
        }
      }

      if (!results.isEmpty()) {
        transformed.setResultObservationUid(String.join(",", results));
      }
      if (!followUps.isEmpty()) {
        transformed.setFollowUpObservationUid(String.join(",", followUps));
      }
    } catch (IllegalArgumentException ex) {
      logger.info(ex.getMessage(), "FollowupObservations", followupObservations);
    } catch (Exception e) {
      logger.error(
          "Error processing Followup Observations JSON array from observation data: {}",
          e.getMessage());
    }
  }

  private static void setParentObservations(
      String parentObservations, ObservationTransformed transformed) {
    try {
      JsonNode parentObservationsJsonArray = parseJsonArray(parentObservations);

      for (JsonNode jsonNode : parentObservationsJsonArray) {
        Long parentUid = getNodeValue(jsonNode, "parent_uid", JsonNode::asLong);
        String parentTypeCd = fieldAsText(jsonNode, "parent_type_cd");
        String parentDomainCd = fieldAsText(jsonNode, "parent_domain_cd_st_1");

        if ("SPRT".equals(parentTypeCd)) {
          transformed.setReportSprtUid(parentUid);
        } else if ("REFR".equals(parentTypeCd)) {
          transformed.setReportRefrUid(parentUid);
        }

        if (parentDomainCd.contains(ORDER)) {
          transformed.setReportObservationUid(parentUid);
        }
      }
    } catch (IllegalArgumentException ex) {
      logger.info(ex.getMessage(), "ParentObservations", parentObservations);
    } catch (Exception e) {
      logger.error(
          "Error processing Parent Observations JSON array from observation data: {}",
          e.getMessage());
    }
  }

  private static void setActIds(String actIds, ObservationTransformed observationTransformed) {
    try {
      JsonNode actIdsJsonArray = parseJsonArray(actIds);

      for (JsonNode jsonNode : actIdsJsonArray) {
        String typeCd = getNodeValue(jsonNode, TYPE_CD, JsonNode::asText);
        Integer actIdSeq = getNodeValue(jsonNode, ACT_ID_SEQ, JsonNode::asInt);
        if (typeCd.equals("FN")) {
          String rootExtTxt = getNodeValue(jsonNode, ROOT_EXTENSION_TXT, JsonNode::asText);
          observationTransformed.setAccessionNumber(rootExtTxt);
        }
        if (typeCd.equals("EII") && actIdSeq.equals(3)) {
          String rootExtTxt = getNodeValue(jsonNode, ROOT_EXTENSION_TXT, JsonNode::asText);
          observationTransformed.setDeviceInstanceId1(rootExtTxt);
        }
        if (typeCd.equals("EII") && actIdSeq.equals(4)) {
          String rootExtTxt = getNodeValue(jsonNode, ROOT_EXTENSION_TXT, JsonNode::asText);
          observationTransformed.setDeviceInstanceId2(rootExtTxt);
        }
      }
    } catch (IllegalArgumentException ex) {
      logger.info(ex.getMessage(), "ActIds", actIds);
    } catch (Exception e) {
      logger.error("Error processing Act Ids JSON array from observation data: {}", e.getMessage());
    }
  }

  private static void setObservationCoded(
      String observationCoded, ParsedObservation parsedObservation) {
    try {
      JsonNode observationCodedJsonArray = parseJsonArray(observationCoded);

      for (JsonNode jsonNode : observationCodedJsonArray) {
        ObservationCoded coded = objectMapper.treeToValue(jsonNode, ObservationCoded.class);
        coded.setBatchId(parsedObservation.transformed().getBatchId());

        parsedObservation.codedEntries().add(coded);
      }
    } catch (IllegalArgumentException ex) {
      logger.info(ex.getMessage(), "ObservationCoded");
    } catch (Exception e) {
      logger.error(
          "Error processing Observation Coded JSON array from observation data: {}",
          e.getMessage());
    }
  }

  private static void setObservationDate(
      String observationDate, ParsedObservation parsedObservation) {
    try {
      JsonNode observationDateJsonArray = parseJsonArray(observationDate);

      for (JsonNode jsonNode : observationDateJsonArray) {
        ObservationDate obsDate = objectMapper.treeToValue(jsonNode, ObservationDate.class);
        obsDate.setBatchId(parsedObservation.transformed().getBatchId());

        parsedObservation.dateEntries().add(obsDate);
      }
    } catch (IllegalArgumentException ex) {
      logger.info(ex.getMessage(), "ObservationDate");
    } catch (Exception e) {
      logger.error(
          "Error processing Observation Date JSON array from observation data: {}", e.getMessage());
    }
  }

  private static void setObservationEdx(
      String observationEdx, ParsedObservation parsedObservation) {
    try {
      JsonNode observationEdxJsonArray = parseJsonArray(observationEdx);
      for (JsonNode jsonNode : observationEdxJsonArray) {
        ObservationEdx edx = objectMapper.treeToValue(jsonNode, ObservationEdx.class);
        edx.setBatchId(parsedObservation.transformed().getBatchId());

        parsedObservation.edxEntries().add(edx);
      }
    } catch (IllegalArgumentException ex) {
      logger.info(ex.getMessage(), "ObservationEdx");
    } catch (Exception e) {
      logger.error(
          "Error processing Observation Edx JSON array from observation data: {}", e.getMessage());
    }
  }

  private static void setObservationNumeric(
      String observationNumeric, ParsedObservation parsedObservation) {
    try {
      JsonNode observationNumericJsonArray = parseJsonArray(observationNumeric);

      for (JsonNode jsonNode : observationNumericJsonArray) {
        ObservationNumeric numeric = objectMapper.treeToValue(jsonNode, ObservationNumeric.class);
        numeric.setBatchId(parsedObservation.transformed().getBatchId());
        parsedObservation.numericEntries().add(numeric);
      }
    } catch (IllegalArgumentException ex) {
      logger.info(ex.getMessage(), "ObservationNumeric");
    } catch (Exception e) {
      logger.error(
          "Error processing Observation Numeric JSON array from observation data: {}",
          e.getMessage());
    }
  }

  private static void setObservationReasons(
      String observationReasons, ParsedObservation parsedObservation) {
    try {
      JsonNode observationReasonsJsonArray = parseJsonArray(observationReasons);

      for (JsonNode jsonNode : observationReasonsJsonArray) {
        ObservationReason reason = objectMapper.treeToValue(jsonNode, ObservationReason.class);
        reason.setBatchId(parsedObservation.transformed().getBatchId());
        parsedObservation.reasonEntries().add(reason);
      }
    } catch (IllegalArgumentException ex) {
      logger.info(ex.getMessage(), "ObservationReasons");
    } catch (Exception e) {
      logger.error(
          "Error processing Observation Reasons JSON array from observation data: {}",
          e.getMessage());
    }
  }

  private static void setObservationTxt(
      String observationTxt, ParsedObservation parsedObservation) {
    try {
      JsonNode observationTxtJsonArray = parseJsonArray(observationTxt);

      for (JsonNode jsonNode : observationTxtJsonArray) {
        ObservationTxt txt = objectMapper.treeToValue(jsonNode, ObservationTxt.class);
        txt.setBatchId(parsedObservation.transformed().getBatchId());

        parsedObservation.textEntries().add(txt);
      }
    } catch (IllegalArgumentException ex) {
      logger.info(ex.getMessage(), "ObservationTxt");
    } catch (Exception e) {
      logger.error(
          "Error processing Observation Txt JSON array from observation data: {}", e.getMessage());
    }
  }

  private static JsonNode parseJsonArray(String jsonString)
      throws JsonProcessingException, IllegalArgumentException {
    JsonNode jsonArray = jsonString != null ? objectMapper.readTree(jsonString) : null;
    if (jsonArray != null && jsonArray.isArray()) {
      return jsonArray;
    } else {
      throw new IllegalArgumentException("{} array is null.");
    }
  }

  private static <T> T getNodeValue(
      JsonNode jsonNode, String fieldName, Function<JsonNode, T> mapper) {
    JsonNode node = jsonNode.get(fieldName);
    if (node == null || node.isNull()) {
      throw new IllegalArgumentException("Field " + fieldName + " is null or not found in {}: {}");
    }
    return mapper.apply(node);
  }

  private static void assertDomainCdMatches(String value, String... vals) {
    if (Arrays.stream(vals).noneMatch(value::equals)) {
      throw new IllegalArgumentException("obsDomainCdSt1: " + value + " is not valid for the {}");
    }
  }

  private static String fieldAsText(JsonNode node, String field) {
    return node.path(field).asText(null);
  }

  private static void ifPresentSet(JsonNode node, String field, Consumer<String> setter) {
    String value = fieldAsText(node, field);
    if (value != null) {
      setter.accept(value);
    }
  }
}
