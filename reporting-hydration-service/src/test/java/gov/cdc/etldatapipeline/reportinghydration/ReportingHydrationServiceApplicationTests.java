package gov.cdc.etldatapipeline.reportinghydration;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.mock;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;

@SpringBootTest
class ReportingHydrationServiceApplicationTests {

  @Autowired private ApplicationContext context;

  @Test
  void contextLoads() {
    assertNotNull(context, "The application context should not be null");
  }

  @Configuration
  static class TestConfiguration {
    @Bean
    public LocalContainerEntityManagerFactoryBean entityManagerFactory() {
      return mock(LocalContainerEntityManagerFactoryBean.class);
    }
  }
}
