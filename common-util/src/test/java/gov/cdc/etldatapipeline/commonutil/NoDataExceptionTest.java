package gov.cdc.etldatapipeline.commonutil;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class NoDataExceptionTest {
    @Test
    void testConstructorWithMessage() {
        String message = "No data found";
        NoDataException exception = new NoDataException(message);

        assertEquals(message, exception.getMessage());
        assertNull(exception.getCause());
    }

    @Test
    void testConstructorWithMessageAndCause() {
        String message = "No data found";
        Throwable cause = new RuntimeException("Underlying cause");
        NoDataException exception = new NoDataException(message, cause);

        assertEquals(message, exception.getMessage());
        assertEquals(cause, exception.getCause());
    }
}
