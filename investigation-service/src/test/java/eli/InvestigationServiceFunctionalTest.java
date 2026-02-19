package eli;

import gov.cdc.etldatapipeline.investigation.service.InvestigationService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(classes = gov.cdc.etldatapipeline.investigation.InvestigationServiceApplication.class)
@ActiveProfiles("functional-test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
public class InvestigationServiceFunctionalTest {
    @Autowired
    private InvestigationService investigationService;

    @Test
    public void contextLoads() {

    }
}
