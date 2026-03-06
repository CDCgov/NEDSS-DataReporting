package gov.cdc.etldatapipeline.controller;

import gov.cdc.etldatapipeline.service.DataPipelineStatusService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DataPipelineController {

  DataPipelineStatusService dataPipelineStatusSvc;

  public DataPipelineController(DataPipelineStatusService dataPipelineStatusSvc) {
    this.dataPipelineStatusSvc = dataPipelineStatusSvc;
  }

  @GetMapping("/status")
  @ResponseBody
  public ResponseEntity<String> getDataPipelineStatusHealth() {
    return this.dataPipelineStatusSvc.getHealthStatus();
  }
}
