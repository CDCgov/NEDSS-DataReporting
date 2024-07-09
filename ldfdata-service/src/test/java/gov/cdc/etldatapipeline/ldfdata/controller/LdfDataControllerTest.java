package gov.cdc.etldatapipeline.ldfdata.controller;

import gov.cdc.etldatapipeline.ldfdata.service.KafkaProducerService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class LdfDataControllerTest {
    private MockMvc mockMvc;

    @Mock
    private KafkaProducerService kafkaProducerService;

    @InjectMocks
    LdfDataController ldfDataController;

    @BeforeEach
    public void setUp() {
        MockitoAnnotations.openMocks(this);
        mockMvc = MockMvcBuilders.standaloneSetup(ldfDataController).build();
    }

    @Test
    void publishMessageToKafkaTest() throws Exception  {
        String jsonData = "{\"key\":\"value\"}";

        mockMvc.perform(post("/reporting/ldfdata-svc/publish")
                        .contentType("application/json")
                        .content(jsonData))
                .andExpect(status().isOk());

        verify(kafkaProducerService).sendMessage(isNull(), eq(jsonData));
    }

    @Test
    void getDataPipelineStatusHealthTest() {
        final String responseBody = "LdfData Preprocessing Service Status OK";

        ResponseEntity<String> response = ldfDataController.getDataPipelineStatusHealth();
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(responseBody, response.getBody());
    }
}

