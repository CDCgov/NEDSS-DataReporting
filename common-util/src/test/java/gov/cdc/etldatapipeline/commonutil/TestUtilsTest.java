package gov.cdc.etldatapipeline.commonutil;

import org.junit.jupiter.api.Test;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;

import static org.junit.jupiter.api.Assertions.*;

class TestUtilsTest {

    @Test
    void testConstructor() throws Exception {
        Constructor<TestUtils> constructor = TestUtils.class.getDeclaredConstructor();
        constructor.setAccessible(true);

        InvocationTargetException exception = assertThrows(InvocationTargetException.class, constructor::newInstance);
        assertInstanceOf(IllegalStateException.class, exception.getCause());
        assertEquals("Utility class", exception.getCause().getMessage());
    }

    @Test
    void testReadFileData_validFile_returnsContent() {
        String fileContent = TestUtils.readFileData("test-data/sample.txt");

        assertNotNull(fileContent);
        assertTrue(fileContent.contains("Hello, this is test content."));
    }

    @Test
    void testReadFileData_fileNotFound_throwsRuntimeException() {
        RuntimeException ex = assertThrows(RuntimeException.class, () -> TestUtils.readFileData("nonexistent-file.txt"));

        assertTrue(ex.getMessage().contains("File Read failed"));
    }
}
