package gov.cdc.etldatapipeline.commonutil;

import com.fasterxml.jackson.core.JsonProcessingException;
import org.junit.jupiter.api.Test;

import java.util.NoSuchElementException;

import static org.junit.jupiter.api.Assertions.*;

class UtilHelperTest {

    private final String sampleJson = """
        {
          "payload": {
            "after": {
              "uid": "12345",
              "name": "Test Name",
              "age": 30
            }
          }
        }
        """;

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
    void testDeserializePayload_invalidJson_returnsNull() {
        String invalidJson = "{ invalid json }";
        assertNull(UtilHelper.deserializePayload(invalidJson, Object.class));
    }

    @Test
    void testExtractUid_validField_returnsValue() throws JsonProcessingException {
        String uid = UtilHelper.extractUid(sampleJson, "uid");
        assertEquals("12345", uid);
    }

    @Test
    void testExtractUid_missingField_throwsException() {
        Exception exception = assertThrows(NoSuchElementException.class, () -> {
            UtilHelper.extractUid(sampleJson, "nonexistentField");
        });

        assertTrue(exception.getMessage().contains("nonexistentField"));
    }

    @Test
    void testExtractValue_validField_returnsValue() throws JsonProcessingException {
        String name = UtilHelper.extractValue(sampleJson, "name");
        assertEquals("Test Name", name);
    }

    @Test
    void testExtractValue_missingField_returnsEmptyString() throws JsonProcessingException {
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
    }
}