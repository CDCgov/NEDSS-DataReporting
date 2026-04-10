package gov.cdc.nbs.report.pipeline.observation.controller;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class ObservationServiceControllerTest {

  private MockMvc mockMvc;

  @Mock private KafkaTemplate<String, String> kafkaTemplate;

  @InjectMocks private ObservationServiceController observationController;

  @BeforeEach
  void setUp() {
    MockitoAnnotations.openMocks(this);
    mockMvc = MockMvcBuilders.standaloneSetup(observationController).build();
  }

  @Test
  void postObservationTest() throws Exception {
    String jsonData = "{\"key\":\"value\"}";

    mockMvc
        .perform(
            post("/reporting/observation-svc/observation")
                .contentType("application/json")
                .content(jsonData))
        .andExpect(status().isOk());

    verify(kafkaTemplate).send(eq("nbs_Observation"), anyString(), eq(jsonData));
  }
}
