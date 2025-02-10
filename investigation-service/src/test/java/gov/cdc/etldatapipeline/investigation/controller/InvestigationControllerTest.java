package gov.cdc.etldatapipeline.investigation.controller;

import gov.cdc.etldatapipeline.investigation.service.KafkaProducerService;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class InvestigationControllerTest {
    private MockMvc mockMvc;

    @Mock
    private KafkaProducerService kafkaProducerService;

    @InjectMocks
    InvestigationController investigationController;

    private AutoCloseable closeable;

    @BeforeEach
    public void setUp() {
        closeable = MockitoAnnotations.openMocks(this);
        mockMvc = MockMvcBuilders.standaloneSetup(investigationController).build();
    }

    @AfterEach
    public void tearDown() throws Exception {
        closeable.close();
    }

    @ParameterizedTest
    @CsvSource({
            "/reporting/investigation-svc/investigation",
            "/reporting/investigation-svc/notification",
            "/reporting/investigation-svc/interview",
            "/reporting/investigation-svc/contact"
    })
    void testControllerMethods(String endpoint) throws Exception  {
        String jsonData = "{\"key\":\"value\"}";

        mockMvc.perform(post(endpoint)
                        .contentType("application/json")
                        .content(jsonData))
                .andExpect(status().isOk());

        verify(kafkaProducerService).sendMessage(isNull(), eq(jsonData));
    }


    @Test
    void getDataPipelineStatusHealthTest() {
        final String responseBody = "Investigation Service Status OK";

        ResponseEntity<String> response = investigationController.getDataPipelineStatusHealth();
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(responseBody, response.getBody());
    }
}

