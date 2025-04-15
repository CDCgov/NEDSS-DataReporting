package gov.cdc.etldatapipeline.commonutil;

import com.fasterxml.jackson.core.JsonProcessingException;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.util.NoSuchElementException;

import static org.junit.jupiter.api.Assertions.*;

class UtilHelperTest {

    private final String sampleJson = """
        {
          "payload": {
            "before": {
              "uid": "12344",
              "name": "Test Name Before",
              "age": 30
            },
            "after": {
              "uid": "12345",
              "name": "Test Name",
              "age": 30
            },
            "op": "d"
          }
        }
        """;

    @Test
    void testConstructor() throws Exception {
        Constructor<UtilHelper> constructor = UtilHelper.class.getDeclaredConstructor();
        constructor.setAccessible(true);

        InvocationTargetException exception = assertThrows(InvocationTargetException.class, constructor::newInstance);
        assertInstanceOf(IllegalStateException.class, exception.getCause());
        assertEquals("Utility class", exception.getCause().getMessage());
    }


    @Test
    void testDeserializePayload_validJson() {
        record Person(String uid, String name, int age) {}
        String json = """
            {
              "uid": "12345",
              "name": "John",
              "age": 25
            }
            """;

        Person person = UtilHelper.deserializePayload(json, Person.class);
        assertNotNull(person);
        assertEquals("12345", person.uid());
        assertEquals("John", person.name());
        assertEquals(25, person.age());
    }

    @Test
    void testDeserializePayload_invalidJson() {
        String invalidJson = "{ invalid json }";
        assertNull(UtilHelper.deserializePayload(invalidJson, Object.class));
    }

    @Test
    void testDeserializePayload_nullJson() {
        String invalidJson = null;
        assertNull(UtilHelper.deserializePayload(invalidJson, Object.class));
    }

    @Test
    void testExtractUid_validField() throws JsonProcessingException {
        String uid = UtilHelper.extractUid(sampleJson, "uid");
        assertEquals("12345", uid);

        uid = UtilHelper.extractUid(sampleJson, "uid", "before");
        assertEquals("12344", uid);
    }

    @Test
    void testExtractUid_invalidField() {
        String inValidJson = """
            {
          "payload": ""
          }
          """;
        Exception exception = assertThrows(NoSuchElementException.class,
                () -> UtilHelper.extractUid(inValidJson, "uid"));
        assertTrue(exception.getMessage().contains("The uid field is missing in the message payload"));
    }

    @Test
    void testExtractUid_missingField() {
        Exception exception = assertThrows(NoSuchElementException.class,
                () -> UtilHelper.extractUid(sampleJson, "nonexistentField"));

        assertTrue(exception.getMessage().contains("nonexistentField"));
    }

    @Test
    void testExtractValue_validField() throws JsonProcessingException {
        String name = UtilHelper.extractValue(sampleJson, "name");
        assertEquals("Test Name", name);

        name = UtilHelper.extractValue(sampleJson, "name", "before");
        assertEquals("Test Name Before", name);
    }

    @Test
    void testExtractValue_missingField() throws JsonProcessingException {
        String value = UtilHelper.extractValue(sampleJson, "missingField");
        assertEquals("", value);  // .asText() on missing node returns ""
    }

    @Test
    void testErrorMessage_withIds() {
        String msg = UtilHelper.errorMessage("Person", "1,2,3", new RuntimeException("Something went wrong"));
        assertTrue(msg.contains("Person"));
        assertTrue(msg.contains("1,2,3"));
        assertTrue(msg.contains("Something went wrong"));
    }

    @Test
    void testErrorMessage_withoutIds() {
        String msg = UtilHelper.errorMessage("Person", "", new RuntimeException("Boom"));
        assertTrue(msg.contains("Person"));
        assertTrue(msg.contains("Boom"));
        assertFalse(msg.contains("with ids"));

        msg = UtilHelper.errorMessage("Person", null, new RuntimeException("Boom"));
        assertFalse(msg.contains("with ids"));
    }

    @Test
    void testExtractCdcOperation() throws JsonProcessingException {
        String value = UtilHelper.extractChangeDataCaptureOperation(sampleJson);
        assertEquals("d", value);
    }
}