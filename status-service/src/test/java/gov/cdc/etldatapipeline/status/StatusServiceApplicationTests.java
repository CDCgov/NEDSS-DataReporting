package gov.cdc.etldatapipeline.status;

import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;

import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest
class StatusServiceApplicationTests {
    @Autowired
    private ApplicationContext context;

    @Test
    void testMain() {
        try (MockedStatic<SpringApplication> mocked = Mockito.mockStatic(SpringApplication.class)) {
            mocked.when(() -> SpringApplication.run(StatusServiceApplication.class, new String[]{}))
                    .thenReturn(null);

            StatusServiceApplication.main(new String[]{});
            mocked.verify(() -> SpringApplication.run(StatusServiceApplication.class, new String[]{}), Mockito.times(1));
        }
    }

    @Test
    void contextLoads() {
        assertNotNull(context, "The application context should not be null");
    }
}
