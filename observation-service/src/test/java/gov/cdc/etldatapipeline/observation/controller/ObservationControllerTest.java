package gov.cdc.etldatapipeline.observation.controller;

import gov.cdc.etldatapipeline.observation.service.KafkaProducerService;
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

public class ObservationControllerTest {

    private MockMvc mockMvc;

    @Mock
    private KafkaProducerService kafkaProducerService;

    @InjectMocks
    private ObservationController observationController;

    @BeforeEach
    public void setUp() {
        MockitoAnnotations.openMocks(this);
        mockMvc = MockMvcBuilders.standaloneSetup(observationController).build();
    }

    @Test
    public void publishMessageToKafkaTest() throws Exception {
        String jsonData = "{\"key\":\"value\"}";

        mockMvc.perform(post("/publish")
                        .contentType("application/json")
                        .content(jsonData))
                .andExpect(status().isOk());

        verify(kafkaProducerService).sendMessage(isNull(), eq(jsonData));
    }

    @Test
    void getDataPipelineStatusHealthTest() {
        final String responseBody = "Observation Service Status OK";

        ResponseEntity<String> response = observationController.getDataPipelineStatusHealth();
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(responseBody, response.getBody());
    }
}

