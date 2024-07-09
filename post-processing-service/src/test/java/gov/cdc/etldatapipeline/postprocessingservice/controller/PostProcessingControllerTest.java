package gov.cdc.etldatapipeline.postprocessingservice.controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.junit.jupiter.api.Assertions.*;

class PostProcessingControllerTest {

    @InjectMocks
    private PostProcessingController postProcessingController;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        MockMvcBuilders.standaloneSetup(postProcessingController).build();
    }

    @Test
    void getDataPipelineStatusHealthTest() {
        final String responseBody = "PostProcessing Reporting Service Status OK";

        ResponseEntity<String> response = postProcessingController.getDataPipelineStatusHealth();
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(responseBody, response.getBody());
    }

}