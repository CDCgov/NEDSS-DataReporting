package gov.cdc.etldatapipeline.postprocessingservice.integration;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.File;
import java.time.Duration;
import java.util.Optional;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.ComposeContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;

import gov.cdc.etldatapipeline.postprocessingservice.integration.patient.PatientCreator;
import gov.cdc.etldatapipeline.postprocessingservice.integration.rdb.DPatientFinder;
import gov.cdc.etldatapipeline.postprocessingservice.integration.util.Await;

@SpringBootTest
@ActiveProfiles("test")
class IntegrationTest {

    @Autowired
    private PatientCreator patientCreator;

    @Autowired
    private DPatientFinder dPatientFinder;

    @SuppressWarnings("resource")
    private static final ComposeContainer environment = new ComposeContainer(
            DockerImageName.parse("docker:25.0.5"),
            new File("../docker-compose.yaml"))
            // List specific services to prevent launching wildfly container
            .withServices(
                    "nbs-mssql",
                    "liquibase",
                    "zookeeper",
                    "kafka",
                    "person-service",
                    "debezium",
                    "kafka-connect")
            // Add liquibase specific log check and increase default timeout
            .waitingFor("liquibase",
                    Wait.forLogMessage("Migrations complete.*", 1).withStartupTimeout(Duration.ofMinutes(3)))
            // Add debezium specific wait to ensure connector is ready before test execution
            .waitingFor("debezium",
                    Wait.forLogMessage("Finished creating connector.*", 3).withStartupTimeout(Duration.ofMinutes(3)))
            // Set a global startup timeout for ComposeContainer
            .withStartupTimeout(Duration.ofMinutes(10));

    @BeforeAll
    static void setUp() {
        // Start up necessary containers
        environment.start();
    }

    @AfterAll
    static void tearDown() {
        // Stop all containers
        environment.stop();
    }

    @Test
    void patientDataIsSuccessfullyProcessed() {
        // Insert a patient into NBS_ODSE
        long createdPatient = patientCreator.create();
        assertThat(createdPatient).isNotZero();

        // Validate patient data arrives in D_PATIENT with retry
        Optional<Long> dPatientKey = Await.waitFor(dPatientFinder::findDPatientKeyWithRetry, createdPatient);

        assertThat(dPatientKey).isPresent();
        assertThat(dPatientKey.get()).isNotZero();
    }

}
