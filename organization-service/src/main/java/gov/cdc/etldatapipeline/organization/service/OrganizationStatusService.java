package gov.cdc.etldatapipeline.organization.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class OrganizationStatusService {

    public OrganizationStatusService() {
    }

    public ResponseEntity<String> getHealthStatus() {
        log.info("Organization Service Status OK");
        return ResponseEntity.status(HttpStatus.OK).body("Organization Service Status OK");
    }
}
