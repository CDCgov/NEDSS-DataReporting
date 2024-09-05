package gov.cdc.etldatapipeline.observation;

import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.mock;

@SpringBootTest
class ObservationServiceApplicationTests {

    @Autowired
    private ApplicationContext context;

    @Test
    void testMain() {
        try (MockedStatic<SpringApplication> mocked = Mockito.mockStatic(SpringApplication.class)) {
            mocked.when(() -> SpringApplication.run(ObservationServiceApplication.class, new String[]{}))
                    .thenReturn(null);

            ObservationServiceApplication.main(new String[]{});
            mocked.verify(() -> SpringApplication.run(ObservationServiceApplication.class, new String[]{}), Mockito.times(1));
        }
    }

    @Test
    void contextLoads() {
        assertNotNull(context, "The application context should not be null");
    }

    @Configuration
    static class TestConfiguration {

        @Bean
        @Primary
        public LocalContainerEntityManagerFactoryBean entityManagerFactory() {
            return mock(LocalContainerEntityManagerFactoryBean.class);
        }
    }
}
