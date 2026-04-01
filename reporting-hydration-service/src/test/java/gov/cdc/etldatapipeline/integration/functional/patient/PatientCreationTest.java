package gov.cdc.etldatapipeline.integration.functional.patient;

import static org.assertj.core.api.Assertions.assertThat;

import gov.cdc.etldatapipeline.integration.functional.FunctionalTest;
import gov.cdc.etldatapipeline.integration.support.Await;
import gov.cdc.etldatapipeline.integration.support.data.patient.PatientManager;
import gov.cdc.etldatapipeline.integration.support.identifier.IdGenerator.GeneratedId;
import java.time.LocalDateTime;
import java.util.Optional;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

@Disabled("Flaky")
class PatientCreationTest extends FunctionalTest {

  @Autowired private PatientManager patientManager;

  @Autowired private DPatientFinder dPatientFinder;

  @Test
  void patientDataIsSuccessfullyProcessed() {
    // Insert a patient into NBS_ODSE
    GeneratedId createdPatient = patientManager.create(LocalDateTime.now());
    assertThat(createdPatient.id()).isNotZero();

    // Validate patient data arrives in D_PATIENT with retry
    Optional<Long> dPatientKey =
        Await.waitFor(dPatientFinder::findDPatientKeyWithRetry, createdPatient.id());

    assertThat(dPatientKey).isPresent();
    assertThat(dPatientKey.get()).isNotZero();
  }
}
