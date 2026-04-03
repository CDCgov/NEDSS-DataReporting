package gov.cdc.etldatapipeline.reportinghydration;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.mock;

import gov.cdc.etldatapipeline.ReportingHydrationServiceApplication;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;

@SpringBootTest
class ReportingHydrationServiceApplicationTests {

  @Autowired private ApplicationContext context;

  @Test
  void testMain() {
    try (MockedStatic<SpringApplication> mocked = Mockito.mockStatic(SpringApplication.class)) {
      mocked
          .when(
              () ->
                  SpringApplication.run(
                      ReportingHydrationServiceApplication.class, new String[] {}))
          .thenReturn(null);

      ReportingHydrationServiceApplication.main(new String[] {});
      mocked.verify(
          () -> SpringApplication.run(ReportingHydrationServiceApplication.class, new String[] {}),
          Mockito.times(1));
    }
  }

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
