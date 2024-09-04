package gov.cdc.etldatapipeline;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.boot.SpringApplication;

import static org.mockito.Mockito.mockStatic;

class EtlDataPipelineApplicationTests {

    @Test
    void testMainMethod() {
        try (var springApplicationMock = mockStatic(SpringApplication.class)) {
            // Act
            EtlDataPipelineApplication.main(new String[]{});

            // Assert
            springApplicationMock.verify(() -> SpringApplication.run(EtlDataPipelineApplication.class, new String[]{}));
        }
    }
    @Test
    void contextLoads() {
        Assertions.assertTrue(true, "Unit Tests sanity check.");
    }
}
