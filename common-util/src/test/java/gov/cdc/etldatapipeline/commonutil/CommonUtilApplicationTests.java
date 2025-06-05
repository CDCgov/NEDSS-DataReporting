package gov.cdc.etldatapipeline.commonutil;

import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Configuration;

import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest
class CommonUtilApplicationTests {

    @Autowired
    private ApplicationContext context;

    @Test
    void testMain() {
        try (MockedStatic<SpringApplication> mocked = Mockito.mockStatic(SpringApplication.class)) {
            mocked.when(() -> SpringApplication.run(CommonUtilApplicationTests.class, new String[]{}))
                    .thenReturn(null);

            CommonUtilApplication.main(new String[]{});
            mocked.verify(() -> SpringApplication.run(CommonUtilApplication.class, new String[]{}), Mockito.times(1));
        }
    }

    @Test
    void contextLoads() {
        assertNotNull(context, "The application context should not be null");
    }

    @Configuration
    static class TestConfiguration {
    }
}
