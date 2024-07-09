package gov.cdc.etldatapipeline.person.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

@Service
public class PersonStatusService {
    private static final Logger LOG = LoggerFactory.getLogger(PersonStatusService.class);

    public PersonStatusService() {
    }

    public ResponseEntity<String> getHealthStatus() {
        LOG.info("Person Service Status OK");
        return ResponseEntity.status(HttpStatus.OK).body("Person Service Status OK");
    }
}
