package gov.cdc.nbs.report.pipeline.postprocessing.service;

import java.nio.charset.StandardCharsets;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.kafka.support.KafkaHeaders;

final class PostProcessingTestUtils {

  static final String INVESTIGATION_TOPIC = "dummy_investigation";
  static final String ORGANIZATION_TOPIC = "dummy_organization";
  static final String PATIENT_TOPIC = "dummy_patient";
  static final String PROVIDER_TOPIC = "dummy_provider";
  static final String NOTIFICATION_TOPIC = "dummy_notification";
  static final String CASE_MANAGEMENT_TOPIC = "dummy_case_management";
  static final String INTERVIEW_TOPIC = "dummy_interview";
  static final String LDF_DATA_TOPIC = "dummy_ldf_data";
  static final String OBSERVATION_TOPIC = "dummy_observation";
  static final String PLACE_TOPIC = "dummy_place";
  static final String AUTH_USER_TOPIC = "dummy_auth_user";
  static final String CONTACT_TOPIC = "dummy_contact";
  static final String TREATMENT_TOPIC = "dummy_treatment";
  static final String VACCINATION_TOPIC = "dummy_vaccination";
  static final String STATE_DEFINED_FIELD_METADATA_TOPIC = "dummy_state_defined_field_metadata";
  static final String NBS_PAGE_TOPIC = "dummy_NBS_page";
  static final String CONDITION_CODE_TOPIC = "dummy_Condition_code";

  private PostProcessingTestUtils() {}

  static void configureNrtTopics(PostProcessingService service) {
    service.setInvestigationTopic(INVESTIGATION_TOPIC);
    service.setOrganizationTopic(ORGANIZATION_TOPIC);
    service.setPatientTopic(PATIENT_TOPIC);
    service.setProviderTopic(PROVIDER_TOPIC);
    service.setNotificationTopic(NOTIFICATION_TOPIC);
    service.setCaseManagementTopic(CASE_MANAGEMENT_TOPIC);
    service.setInterviewTopic(INTERVIEW_TOPIC);
    service.setLdfDataTopic(LDF_DATA_TOPIC);
    service.setObservationTopic(OBSERVATION_TOPIC);
    service.setPlaceTopic(PLACE_TOPIC);
    service.setAuthUserTopic(AUTH_USER_TOPIC);
    service.setContactTopic(CONTACT_TOPIC);
    service.setTreatmentTopic(TREATMENT_TOPIC);
    service.setVaccinationTopic(VACCINATION_TOPIC);
    service.setStateDefinedFieldMetadataTopic(STATE_DEFINED_FIELD_METADATA_TOPIC);
    service.setNbsPageTopic(NBS_PAGE_TOPIC);
    service.setConditionCodeTopic(CONDITION_CODE_TOPIC);
  }

  static ConsumerRecord<String, String> retryRecord(
      String retryTopic, String originalTopic, String key, String payload) {
    ConsumerRecord<String, String> record = new ConsumerRecord<>(retryTopic, 0, 11L, key, payload);
    record
        .headers()
        .add(KafkaHeaders.ORIGINAL_TOPIC, originalTopic.getBytes(StandardCharsets.UTF_8));
    return record;
  }
}
