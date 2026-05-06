package gov.cdc.nbs.report.pipeline.util;

import static org.junit.jupiter.api.Assertions.*;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import org.junit.jupiter.api.Test;

class TestUtilsTest {

  @Test
  void testConstructor() throws Exception {
    Constructor<TestUtils> constructor = TestUtils.class.getDeclaredConstructor();
    constructor.setAccessible(true);

    InvocationTargetException exception =
        assertThrows(InvocationTargetException.class, constructor::newInstance);
    assertInstanceOf(IllegalStateException.class, exception.getCause());
    assertEquals("Utility class", exception.getCause().getMessage());
  }

  @Test
  void testReadFileData_validFile_returnsContent() {
    String fileContent = TestUtils.readFileData("testData/fileUtilData.txt");

    assertNotNull(fileContent);
    assertTrue(fileContent.contains("Hello, this is test content."));
  }

  @Test
  void testReadFileData_fileNotFound_throwsRuntimeException() {
    RuntimeException ex =
        assertThrows(RuntimeException.class, () -> TestUtils.readFileData("nonexistent-file.txt"));

    assertTrue(ex.getMessage().contains("File Read failed"));
  }
}
