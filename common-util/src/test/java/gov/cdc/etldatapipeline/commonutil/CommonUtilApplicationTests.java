package gov.cdc.etldatapipeline.commonutil;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

@SpringBootTest
class CommonUtilApplicationTests {

    @Test
    void testMainMethod_runsWithoutException() {
        assertDoesNotThrow(() -> CommonUtilApplication.main(new String[]{}));
    }
}
