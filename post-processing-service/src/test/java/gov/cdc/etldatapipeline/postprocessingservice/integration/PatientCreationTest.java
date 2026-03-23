package gov.cdc.etldatapipeline.postprocessingservice.integration;

import static org.assertj.core.api.Assertions.assertThat;

import gov.cdc.etldatapipeline.postprocessingservice.integration.patient.PatientCreator;
import gov.cdc.etldatapipeline.postprocessingservice.integration.rdb.DPatientFinder;
import gov.cdc.etldatapipeline.postprocessingservice.integration.util.Await;
import java.util.Optional;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class PatientCreationTest extends IntegrationTest {

  private static final Logger logger = LoggerFactory.getLogger(PatientCreationTest.class);

  @BeforeAll
  static void listContainers() {
    logger.info("Listing all running containers:");
    try {
      new ProcessBuilder("docker", "ps").inheritIO().start().waitFor();
    } catch (Exception e) {
      logger.error("Failed to list containers: {}", e.getMessage());
    }
  }

  @Autowired private PatientCreator patientCreator;
  @Autowired private DPatientFinder dPatientFinder;

  @Test
  void patientDataIsSuccessfullyProcessed() {
    // Insert a patient into NBS_ODSE
    long createdPatient = patientCreator.create();
    assertThat(createdPatient).isNotZero();

    // Validate patient data arrives in D_PATIENT with retry
    Optional<Long> dPatientKey =
        Await.waitFor(dPatientFinder::findDPatientKeyWithRetry, createdPatient);

    assertThat(dPatientKey).isPresent();
    assertThat(dPatientKey.get()).isNotZero();
  }
}
