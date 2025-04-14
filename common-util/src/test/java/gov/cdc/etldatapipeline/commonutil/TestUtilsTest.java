package gov.cdc.etldatapipeline.commonutil;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class TestUtilsTest {

    @Test
    void testReadFileData_validFile_returnsContent() {
        String fileContent = TestUtils.readFileData("test-data/sample.txt");

        assertNotNull(fileContent);
        assertTrue(fileContent.contains("Hello, this is test content."));
    }

    @Test
    void testReadFileData_fileNotFound_throwsRuntimeException() {
        RuntimeException ex = assertThrows(RuntimeException.class, () -> {
            TestUtils.readFileData("nonexistent-file.txt");
        });

        assertTrue(ex.getMessage().contains("File Read failed"));
    }
}
