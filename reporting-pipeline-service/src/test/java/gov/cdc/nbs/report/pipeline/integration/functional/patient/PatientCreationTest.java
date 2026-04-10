package gov.cdc.nbs.report.pipeline.integration.functional.patient;

import static org.assertj.core.api.Assertions.assertThat;

import gov.cdc.nbs.report.pipeline.integration.functional.FunctionalTest;
import gov.cdc.nbs.report.pipeline.integration.support.Await;
import gov.cdc.nbs.report.pipeline.integration.support.data.patient.PatientManager;
import gov.cdc.nbs.report.pipeline.integration.support.identifier.IdGenerator.GeneratedId;
import java.time.LocalDateTime;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

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
