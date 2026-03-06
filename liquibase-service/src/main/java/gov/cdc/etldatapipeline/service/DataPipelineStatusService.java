package gov.cdc.etldatapipeline.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

@Service
public class DataPipelineStatusService {
  private static final Logger LOG = LoggerFactory.getLogger(DataPipelineStatusService.class);

  public DataPipelineStatusService() {}

  public ResponseEntity<String> getHealthStatus() {
    LOG.info("Status OK");
    return ResponseEntity.status(HttpStatus.OK).body("Status OK");
  }
}
