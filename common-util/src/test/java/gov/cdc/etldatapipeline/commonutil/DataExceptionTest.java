package gov.cdc.etldatapipeline.commonutil;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

import java.lang.reflect.Constructor;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class DataExceptionTest {

    static Stream<Arguments> messageOnlyProvider() {
        return Stream.of(
                Arguments.of(NoDataException.class, "No data found"),
                Arguments.of(DataProcessingException.class, "Processing error")
        );
    }

    static Stream<Arguments> messageAndCauseProvider() {
        return Stream.of(
                Arguments.of(
                        NoDataException.class,
                        "No data found",
                        new RuntimeException("Underlying cause")
                ),
                Arguments.of(
                        DataProcessingException.class,
                        "Processing error",
                        new IllegalStateException("Bad state")
                )
        );
    }

    @ParameterizedTest(name = "{0}.<init>(\"{1}\")")
    @MethodSource("messageOnlyProvider")
    <T extends RuntimeException> void testConstructorWithMessage(
            Class<T> exceptionClass,
            String message
    ) throws Exception {
        Constructor<T> ctor = exceptionClass.getConstructor(String.class);
        T ex = ctor.newInstance(message);

        assertEquals(message,    ex.getMessage());
        assertNull(ex.getCause());
    }

    @ParameterizedTest(name = "{0}.<init>(\"{1}\", cause={2})")
    @MethodSource("messageAndCauseProvider")
    <T extends RuntimeException> void testConstructorWithMessageAndCause(
            Class<T> exceptionClass,
            String message,
            Throwable cause
    ) throws Exception {
        Constructor<T> ctor = exceptionClass.getConstructor(String.class, Throwable.class);
        T ex = ctor.newInstance(message, cause);

        assertEquals(message, ex.getMessage());
        assertEquals(cause,   ex.getCause());
    }
}
