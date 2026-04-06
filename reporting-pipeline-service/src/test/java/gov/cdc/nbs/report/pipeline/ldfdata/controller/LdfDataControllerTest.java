package gov.cdc.nbs.report.pipeline.ldfdata.controller;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import gov.cdc.nbs.report.pipeline.ldfdata.service.KafkaProducerService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class LdfDataControllerTest {
  private MockMvc mockMvc;

  @Mock private KafkaProducerService kafkaProducerService;

  @InjectMocks LdfDataController ldfDataController;

  @BeforeEach
  public void setUp() {
    MockitoAnnotations.openMocks(this);
    mockMvc = MockMvcBuilders.standaloneSetup(ldfDataController).build();
  }

  @Test
  void publishMessageToKafkaTest() throws Exception {
    String jsonData = "{\"key\":\"value\"}";

    mockMvc
        .perform(
            post("/reporting/ldfdata-svc/publish")
                .contentType("application/json")
                .content(jsonData))
        .andExpect(status().isOk());

    verify(kafkaProducerService).sendMessage(isNull(), eq(jsonData));
  }
}
