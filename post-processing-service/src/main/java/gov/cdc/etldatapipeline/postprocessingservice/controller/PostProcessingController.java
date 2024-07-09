package gov.cdc.etldatapipeline.postprocessingservice.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@Slf4j
public class PostProcessingController {

    @GetMapping("/reporting/post-processing-svc/status")
    @ResponseBody
    public ResponseEntity<String> getDataPipelineStatusHealth() {
        log.info("Post Processing Reporting Service Status OK");
        return ResponseEntity.status(HttpStatus.OK).body("PostProcessing Reporting Service Status OK");
    }
}
