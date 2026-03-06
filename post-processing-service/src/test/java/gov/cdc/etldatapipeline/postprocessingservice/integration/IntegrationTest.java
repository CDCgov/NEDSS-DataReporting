package gov.cdc.etldatapipeline.postprocessingservice.integration;

import java.io.File;
import java.time.Duration;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.ComposeContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;

class IntegrationTest {

    @SuppressWarnings("resource")
    private static final ComposeContainer environment = new ComposeContainer(
            DockerImageName.parse("docker:25.0.5"),
            new File("../docker-compose.yaml"))
            .withServices(
                    "nbs-mssql",
                    "liquibase",
                    "zookeeper",
                    "kafka",
                    "debezium",
                    "kafka-connect",
                    "person-service",
                    "post-processing-service")
            .waitingFor("liquibase",
                    Wait.forLogMessage("Migrations complete.*", 1).withStartupTimeout(Duration.ofMinutes(3)))
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
    void patientDataIsSuccessfullyProcessed() throws InterruptedException {
        System.out.println("Starting test...");
        Thread.sleep(Duration.ofSeconds(10)); // Testing that container comes up
        System.out.println("Test complete...");
        // Insert a patient into NBS_ODSE

        // Validate patient data arrives in D_PATIENT
    }

}
