package gov.cdc.etldatapipeline.postprocessingservice.integration;

import static org.assertj.core.api.Assertions.assertThat;

import gov.cdc.etldatapipeline.postprocessingservice.integration.rdb.DPatientFinder;
import gov.cdc.etldatapipeline.testing.IntegrationTest;
import gov.cdc.etldatapipeline.testing.patient.PatientManager;
import gov.cdc.etldatapipeline.testing.util.Await;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.simple.JdbcClient;

@SpringBootTest
class PatientCreationTest extends IntegrationTest {

  private PatientManager patientManager = null;
  private DPatientFinder dPatientFinder = null;

  public PatientCreationTest(
      @Qualifier("rdbClient") JdbcClient jdbcClient,
      @Qualifier("odseClient") JdbcClient odseClient) {
    // must manually create due to class is in imported testing lib
    this.patientManager = new PatientManager(odseClient);
    this.dPatientFinder = new DPatientFinder(jdbcClient);
  }

  @Test
  void patientDataIsSuccessfullyProcessed() {
    // Insert a patient into NBS_ODSE
    long createdPatient = patientManager.create();
    assertThat(createdPatient).isNotZero();

    // Validate patient data arrives in D_PATIENT with retry
    Optional<Long> dPatientKey =
        Await.waitFor(dPatientFinder::findDPatientKeyWithRetry, createdPatient);

    assertThat(dPatientKey).isPresent();
    assertThat(dPatientKey.get()).isNotZero();
  }
}
